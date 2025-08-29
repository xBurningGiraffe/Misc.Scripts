import Foundation
import CoreBluetooth
import Combine

class BleNmeaManager: NSObject, ObservableObject {
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var dataCharacteristic: CBCharacteristic?
    
    @Published var log: [String] = []
    @Published var connected = false
    
    // Replace with your ESP32 characteristic UUID if fixed
    private let nmeaServiceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    private let nmeaCharUUID    = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan() {
        log.append("Scanning for OpenDragy-NMEA...")
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func disconnect() {
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
        }
    }
}

extension BleNmeaManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            log.append("Bluetooth is powered on")
        case .poweredOff:
            log.append("Bluetooth is off")
        default:
            log.append("Bluetooth state: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "(no name)"
        log.append("Discovered: \(name)")
        
        if name.contains("OpenDragy-NMEA") {
            log.append("Connecting to \(name)")
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.append("Connected to \(peripheral.name ?? "(no name)")")
        connected = true
        peripheral.discoverServices([nmeaServiceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                log.append("Service: \(service.uuid)")
                if service.uuid == nmeaServiceUUID {
                    peripheral.discoverCharacteristics([nmeaCharUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let chars = service.characteristics {
            for c in chars {
                log.append("Characteristic: \(c.uuid)")
                if c.uuid == nmeaCharUUID {
                    dataCharacteristic = c
                    peripheral.setNotifyValue(true, for: c)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let value = characteristic.value,
           let text = String(data: value, encoding: .utf8) {
            log.append("RX: \(text)")
        }
    }
}

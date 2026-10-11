#include <stdio.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

int main(void) {
    int serveur = socket(AF_INET, SOCK_STREAM, 0);
    if (serveur < 0) {
        perror("socket");
        return 1;
    }

    struct sockaddr_in adresse = {
        .sin_family = AF_INET,
        .sin_port = htons(9090),
        .sin_addr.s_addr = htonl(INADDR_LOOPBACK)
    };

    if (bind(serveur, (struct sockaddr *)&adresse,
             sizeof(adresse)) < 0 ||
        listen(serveur, 1) < 0) {
        perror("bind/listen");
        close(serveur);
        return 1;
    }

    printf("Serveur en attente sur 127.0.0.1:9090\n");
    fflush(stdout);

    int client = accept(serveur, NULL, NULL);
    if (client >= 0) {
        const char message[] = "Connexion OK\n";
        write(client, message, sizeof(message) - 1);
        close(client);
    }

    close(serveur);
    return 0;
}

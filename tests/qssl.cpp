// n9-tls test: QSslSocket over TLS 1.2 (optionally after the process already initialised system OpenSSL 0.9.8)
#include <QtCore/QCoreApplication>
#include <QtCore/QFile>
#include <QtNetwork/QSslSocket>
#include <QtNetwork/QSslCipher>
#include <QtNetwork/QSslCertificate>
#include <cstdio>
extern "C" int SSL_library_init(void);
extern "C" const char *SSLeay_version(int);
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    if (argc > 4) { SSL_library_init(); printf("system OpenSSL in process: %s\n", SSLeay_version(0)); }
    printf("QSslSocket::supportsSsl: %d\n", QSslSocket::supportsSsl());
    { QList<QSslCipher> dc = QSslSocket::defaultCiphers(); printf("default ciphers: %d:", dc.size()); for (int i = 0; i < dc.size() && i < 8; ++i) printf(" %s", qPrintable(dc.at(i).name())); printf("\n"); }
    QList<QSslCertificate> ca = QSslCertificate::fromPath(argv[3]);
    QSslSocket s; s.setCaCertificates(ca);
    s.connectToHostEncrypted(argv[1], QString(argv[2]).toInt());
    bool ok = s.waitForEncrypted(15000);
    printf("encrypted: %d  error: %s\n", ok, qPrintable(s.errorString()));
    if (ok) {
        QSslCipher c = s.sessionCipher();
        printf("cipher: %s  protocol string: %s\n", qPrintable(c.name()), qPrintable(c.protocolString()));
        s.write("GET / HTTP/1.0\r\n\r\n"); s.waitForReadyRead(5000);
        printf("reply: %s\n", s.readLine().trimmed().constData());
    }
    return ok ? 0 : 1;
}

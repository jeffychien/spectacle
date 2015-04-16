#ifndef KSCREENGENIE_H
#define KSCREENGENIE_H

#include <QUrl>
#include <QFile>
#include <QTemporaryFile>
#include <QString>
#include <QStringList>
#include <QByteArray>
#include <QDateTime>
#include <QImageWriter>
#include <QErrorMessage>
#include <QMimeDatabase>
#include <QMimeType>
#include <QStandardPaths>
#include <QFileDialog>
#include <QDir>
#include <QClipboard>
#include <QTimer>
#include <QDebug>

#include <KLocalizedString>
#include <KJob>
#include <KRun>
#include <KService>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KWindowSystem>
#include <KIO/FileCopyJob>
#include <KIO/StatJob>

#include "ImageGrabber.h"
#include "X11ImageGrabber.h"
#include "KScreenGenieGUI.h"

class KScreenGenie : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString filename READ filename WRITE setFilename NOTIFY filenameChanged)
    Q_PROPERTY(bool overwriteOnSave READ overwriteOnSave WRITE setOverwriteOnSave NOTIFY overwriteOnSaveChanged)
    Q_PROPERTY(ImageGrabber::GrabMode grabMode READ grabMode WRITE setGrabMode NOTIFY grabModeChanged)
    Q_PROPERTY(QString saveLocation READ saveLocation WRITE setSaveLocation NOTIFY saveLocationChanged)

    public:

    explicit KScreenGenie(bool background, bool startEditor, ImageGrabber::GrabMode grabMode, QObject *parent = 0);
    ~KScreenGenie();

    QString filename() const;
    void setFilename(const QString &filename);
    ImageGrabber::GrabMode grabMode() const;
    void setGrabMode(const ImageGrabber::GrabMode grabMode);
    bool overwriteOnSave() const;
    void setOverwriteOnSave(const bool overwrite);
    QString saveLocation() const;
    void setSaveLocation(const QString &savePath);

    signals:

    void errorMessage(const QString err_string);
    void allDone();
    void filenameChanged(QString filename);
    void grabModeChanged(ImageGrabber::GrabMode mode);
    void overwriteOnSaveChanged(bool overwriteOnSave);
    void saveLocationChanged(QString savePath);
    void imageSaved();

    public slots:

    void takeNewScreenshot(ImageGrabber::GrabMode mode, int timeout, bool includePointer, bool includeDecorations);
    void showErrorMessage(const QString err_string);
    void screenshotUpdated(const QPixmap pixmap);
    void screenshotFailed();
    void doGuiSaveAs();
    void doAutoSave();
    void doSendToService(KService::Ptr service);
    void doSendToOpenWith();
    void doSendToClipboard();

    private:

    QUrl getAutoSaveFilename();
    QString makeTimestampFilename();
    QString makeSaveMimetype(const QUrl url);
    bool writeImage(QIODevice *device, const QByteArray &format);
    bool localSave(const QUrl url, const QString mimetype);
    bool remoteSave(const QUrl url, const QString mimetype);
    QUrl tempFileSave(const QString mimetype = "png");
    bool doSave(const QUrl url);
    bool isFileExists(const QUrl url);

    bool             mBackgroundMode;
    bool             mOverwriteOnSave;
    bool             mStartEditor;
    QPixmap          mLocalPixmap;
    QString          mFileNameString;
    QUrl             mFileNameUrl;
    ImageGrabber    *mImageGrabber;
    KScreenGenieGUI *mScreenGenieGUI;
};

#endif // KSCREENGENIE_H

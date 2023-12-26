/*
 *  SPDX-FileCopyrightText: 2019 David Redondo <kde@david-redondo.de>
 *  SPDX-FileCopyrightText: 2015 Boudhayan Gupta <bgupta@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "VideoSaveOptionsPage.h"

#include "Platforms/VideoPlatform.h"
#include "SpectacleCore.h"
#include "ExportManager.h"
#include "SaveOptionsUtils.h"
#include "VideoFormatModel.h"
#include "ui_VideoSaveOptions.h"

#include <KLocalizedString>

#include <QCheckBox>
#include <QComboBox>
#include <QFontDatabase>
#include <QImageWriter>
#include <QLabel>
#include <QLineEdit>

using namespace Qt::StringLiterals;

VideoSaveOptionsPage::VideoSaveOptionsPage(QWidget *parent)
    : QWidget(parent)
    , m_ui(new Ui_VideoSaveOptions)
{
    m_ui->setupUi(this);

    const auto videoFormatModel = SpectacleCore::instance()->videoFormatModel();

    // Auto select the correct format if the user types an extension in the filename template.
    connect(m_ui->kcfg_videoFilenameTemplate, &QLineEdit::textEdited, this, [this, videoFormatModel](const QString &text) {
        const auto count = videoFormatModel->rowCount();
        for (auto i = 0; i < count; ++i) {
            auto index = videoFormatModel->index(i);
            auto extension = index.data(VideoFormatModel::ExtensionRole).toString();
            if (text.endsWith(u'.' + extension, Qt::CaseInsensitive)) {
                m_ui->kcfg_videoFilenameTemplate->setText(text.chopped(extension.length() + 1));
                m_ui->videoFormatComboBox->setCurrentIndex(i);
            }
        }
    });
    connect(m_ui->kcfg_videoFilenameTemplate, &QLineEdit::textChanged,
            this, &VideoSaveOptionsPage::updateFilenamePreview);

    m_ui->videoFormatComboBox->setModel(videoFormatModel);
    const auto format = static_cast<VideoPlatform::Format>(Settings::preferredVideoFormat());
    m_ui->videoFormatComboBox->setCurrentIndex(videoFormatModel->indexOfFormat(format));
    connect(m_ui->videoFormatComboBox, &QComboBox::currentIndexChanged, this, [this] {
        const auto format = m_ui->videoFormatComboBox->currentData(VideoFormatModel::FormatRole);
        Settings::setPreferredVideoFormat(format.value<VideoPlatform::Format>());
    });
    connect(m_ui->videoFormatComboBox, &QComboBox::currentTextChanged, this, &VideoSaveOptionsPage::updateFilenamePreview);

    m_ui->captureInstructionLabel->setText(captureInstructions(false));
    connect(m_ui->captureInstructionLabel, &QLabel::linkActivated, this, [this](const QString &link) {
        if (link == u"showmore"_s) {
            m_ui->captureInstructionLabel->setText(captureInstructions(true));
        } else if (link == u"showless"_s) {
            m_ui->captureInstructionLabel->setText(captureInstructions(false));
        } else {
            m_ui->kcfg_videoFilenameTemplate->insert(link);
        }
    });
}

VideoSaveOptionsPage::~VideoSaveOptionsPage() = default;

void VideoSaveOptionsPage::updateFilenamePreview()
{
    const auto extension = m_ui->videoFormatComboBox->currentData(VideoFormatModel::ExtensionRole).toString();
    const auto templateBasename = m_ui->kcfg_videoFilenameTemplate->text();
    ::updateFilenamePreview(m_ui->preview, templateBasename + u'.' + extension);
}

#include "moc_VideoSaveOptionsPage.cpp"

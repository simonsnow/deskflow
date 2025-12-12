/*
 * Deskflow -- mouse and keyboard sharing utility
 * SPDX-FileCopyrightText: (C) 2025 Deskflow Developers
 * SPDX-License-Identifier: GPL-2.0-only WITH LicenseRef-OpenSSL-Exception
 */

#include "StateFileWriter.h"

#include "base/Log.h"
#include "common/Settings.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

namespace deskflow {

void StateFileWriter::writeState(bool active)
{
  if (!Settings::value(Settings::State::ToFile).toBool()) {
    // State file writing is disabled
    LOG_DEBUG2("state file writing is disabled");
    return;
  }

  auto file = Settings::value(Settings::State::File).toString().trimmed();
  if (file.isEmpty()) {
    file = Settings::defaultValue(Settings::State::File).toString();
  }

  LOG_DEBUG1("writing state '%d' to file: %s", active ? 1 : 0, qPrintable(file));
  writeToFile(file, active);
}

void StateFileWriter::writeToFile(const QString &filePath, bool active)
{
  if (filePath.isEmpty()) {
    LOG_WARN("state file path is empty, cannot write");
    return;
  }

  // Ensure directory exists
  QFileInfo fileInfo(filePath);
  QDir dir = fileInfo.absoluteDir();
  if (!dir.exists()) {
    LOG_DEBUG1("creating directory for state file: %s", qPrintable(dir.absolutePath()));
    if (!dir.mkpath(".")) {
      LOG_ERR("failed to create directory for state file: %s", qPrintable(dir.absolutePath()));
      return;
    }
  }

  // Write the state atomically
  QFile file(filePath);
  if (!file.open(QFile::WriteOnly | QFile::Truncate | QFile::Text)) {
    LOG_ERR("failed to open state file for writing: %s", qPrintable(filePath));
    return;
  }

  QTextStream stream(&file);
  stream << (active ? "1" : "0") << Qt::endl;
  file.close();

  LOG_DEBUG2("state file written successfully: %s", qPrintable(filePath));
}

} // namespace deskflow

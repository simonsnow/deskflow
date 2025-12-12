/*
 * Deskflow -- mouse and keyboard sharing utility
 * SPDX-FileCopyrightText: (C) 2025 Deskflow Developers
 * SPDX-FileCopyrightText: (C) 2012 - 2016 Symless Ltd.
 * SPDX-FileCopyrightText: (C) 2002 Chris Schoeneman
 * SPDX-License-Identifier: GPL-2.0-only WITH LicenseRef-OpenSSL-Exception
 */

#include "base/LogOutputters.h"
#include "arch/Arch.h"
#include "common/Constants.h"

#include <iostream>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QString>
#include <QTextStream>

constexpr auto s_logFileSizeLimit = 1024 * 1024; //!< Max Log size before rotating (1Mb)

//
// StopLogOutputter
//

void StopLogOutputter::open(const QString &)
{
  // do nothing
}

void StopLogOutputter::close()
{
  // do nothing
}

bool StopLogOutputter::write(LogLevel, const QString &)
{
  return false;
}

//
// ConsoleLogOutputter
//

void ConsoleLogOutputter::open(const QString &title)
{
  // do nothing
}

void ConsoleLogOutputter::close()
{
  // do nothing
}

bool ConsoleLogOutputter::write(LogLevel level, const QString &msg)
{
  if ((level >= LogLevel::Fatal) && (level <= LogLevel::Warning))
    std::cerr << qPrintable(msg) << std::endl;
  else
    std::cout << qPrintable(msg) << std::endl;
  std::cout.flush();
  return true;
}

void ConsoleLogOutputter::flush() const
{
  // do nothing
}

//
// SystemLogOutputter
//

void SystemLogOutputter::open(const QString &title)
{
  ARCH->openLog(title);
}

void SystemLogOutputter::close()
{
  ARCH->closeLog();
}

bool SystemLogOutputter::write(LogLevel level, const QString &msg)
{
  ARCH->writeLog(level, msg);
  return true;
}

//
// SystemLogger
//

SystemLogger::SystemLogger(const QString &title, bool blockConsole)
{
  // redirect log messages
  if (blockConsole) {
    m_stop = new StopLogOutputter; // NOSONAR - Adopted by `Log`
    CLOG->insert(m_stop);
  }
  m_syslog = new SystemLogOutputter; // NOSONAR - Adopted by `Log`
  m_syslog->open(title);
  CLOG->insert(m_syslog);
}

SystemLogger::~SystemLogger()
{
  CLOG->remove(m_syslog);
  delete m_syslog;
  if (m_stop != nullptr) {
    CLOG->remove(m_stop);
    delete m_stop;
  }
}

//
// FileLogOutputter
//

FileLogOutputter::FileLogOutputter(const QString &logFile)
{
  setLogFilename(logFile);
}

void FileLogOutputter::setLogFilename(const QString &logFile)
{
  auto fileName = logFile.trimmed();

  // Fallback to a sensible default if an empty or whitespace-only path is provided.
  if (fileName.isEmpty()) {
    fileName = QStringLiteral("%1/%2").arg(QDir::homePath(), QString::fromLatin1(kDefaultLogFile));
  }

  if (fileName.isEmpty()) {
    qWarning("FileLogOutputter: empty log filename specified");
    return;
  }

  m_fileName = fileName;
}

bool FileLogOutputter::write(LogLevel, const QString &message)
{
  if (m_fileName.isEmpty()) {
    return false;
  }

  // Ensure directory exists
  QFileInfo fileInfo(m_fileName);
  QDir dir = fileInfo.absoluteDir();
  if (!dir.exists()) {
    dir.mkpath(".");
  }

  QFile file(m_fileName);
  if (!file.open(QFile::WriteOnly | QFile::Append))
    return false;

  QTextStream(&file) << message << Qt::endl;
  file.close();

  if (file.size() > s_logFileSizeLimit) {
    const auto oldFile = QStringLiteral("%1.1").arg(m_fileName);
    QFile::remove(m_fileName);
    QFile::rename(m_fileName, oldFile);
  }

  return true;
}

void FileLogOutputter::open(const QString &title)
{
  // do nothing
}

void FileLogOutputter::close()
{
  // do nothing
}

/*
 * Deskflow -- mouse and keyboard sharing utility
 * SPDX-FileCopyrightText: (C) 2025 Deskflow Developers
 * SPDX-License-Identifier: GPL-2.0-only WITH LicenseRef-OpenSSL-Exception
 */

#pragma once

#include <QString>

namespace deskflow {

/// @brief Utility class for managing the state file
///
/// The state file is a simple text file that contains "1" when the
/// current Deskflow instance is active (has control), otherwise "0".
class StateFileWriter
{
public:
  /// @brief Writes the active state to the configured state file
  /// @param active true if this instance is active, false otherwise
  static void writeState(bool active);

private:
  static void writeToFile(const QString &filePath, bool active);
};

} // namespace deskflow

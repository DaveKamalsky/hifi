//
//  RefreshRateManager.cpp
//  interface/src/
//
//  Created by Dante Ruiz on 2019-04-15.
//  Copyright 2019 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//


#include "RefreshRateManager.h"

#include <array>


static const int VR_TARGET_RATE = 90;

static const std::array<std::string, RefreshRateManager::RefreshRateProfile::PROFILE_NUM> REFRESH_RATE_PROFILE_TO_STRING =
    { { "Eco", "Interactive", "Realtime" } };

static const std::array<std::string, RefreshRateManager::RefreshRateRegime::REGIME_NUM> REFRESH_RATE_REGIME_TO_STRING =
    { { "FocusActive", "FocusInactive", "Unfocus", "Minimized", "StartUp", "ShutDown" } };

static const std::array<std::string, RefreshRateManager::UXMode::UX_NUM> UX_MODE_TO_STRING =
    { { "Desktop", "VR" } };

static const std::map<std::string, RefreshRateManager::RefreshRateProfile> REFRESH_RATE_PROFILE_FROM_STRING =
    { { "Eco", RefreshRateManager::RefreshRateProfile::ECO },
      { "Interactive", RefreshRateManager::RefreshRateProfile::INTERACTIVE },
      { "Realtime", RefreshRateManager::RefreshRateProfile::REALTIME } };


// Porfile regimes are:
//  { { "FocusActive", "FocusInactive", "Unfocus", "Minimized", "StartUp", "ShutDown" } }

static const std::array<int, RefreshRateManager::RefreshRateRegime::REGIME_NUM> ECO_PROFILE =
    { { 20, 10, 5, 2, 30, 30 } };

static const std::array<int, RefreshRateManager::RefreshRateRegime::REGIME_NUM> INTERACTIVE_PROFILE =
    { { 30, 20, 10, 2, 30, 30 } };

static const std::array<int, RefreshRateManager::RefreshRateRegime::REGIME_NUM> REALTIME_PROFILE =
    { { 60, 60, 10, 2, 30, 30} };

static const std::array<std::array<int, RefreshRateManager::RefreshRateRegime::REGIME_NUM>, RefreshRateManager::RefreshRateProfile::PROFILE_NUM> REFRESH_RATE_PROFILES =
    { { ECO_PROFILE, INTERACTIVE_PROFILE, REALTIME_PROFILE } };


static const int INACTIVE_TIMER_LIMIT = 3000;


std::string RefreshRateManager::refreshRateProfileToString(RefreshRateManager::RefreshRateProfile refreshRateProfile) {
    return REFRESH_RATE_PROFILE_TO_STRING.at(refreshRateProfile);
}

RefreshRateManager::RefreshRateProfile RefreshRateManager::refreshRateProfileFromString(std::string refreshRateProfile) {
    return REFRESH_RATE_PROFILE_FROM_STRING.at(refreshRateProfile);
}

std::string RefreshRateManager::refreshRateRegimeToString(RefreshRateManager::RefreshRateRegime refreshRateRegime) {
    return REFRESH_RATE_REGIME_TO_STRING.at(refreshRateRegime);
}

std::string RefreshRateManager::uxModeToString(RefreshRateManager::RefreshRateManager::UXMode uxMode) {
    return UX_MODE_TO_STRING.at(uxMode);
}

RefreshRateManager::RefreshRateManager() {
    _refreshRateProfile = (RefreshRateManager::RefreshRateProfile) _refreshRateProfileSetting.get();
    _inactiveTimer->setInterval(INACTIVE_TIMER_LIMIT);
    _inactiveTimer->setSingleShot(true);
    QObject::connect(_inactiveTimer.get(), &QTimer::timeout, [&] {
        toggleInactive();
    });
}

void RefreshRateManager::resetInactiveTimer() {
    if (_uxMode == RefreshRateManager::UXMode::DESKTOP) {
        auto regime = getRefreshRateRegime();
        if (regime == RefreshRateRegime::FOCUS_ACTIVE || regime == RefreshRateRegime::FOCUS_INACTIVE) {
            _inactiveTimer->start();
            setRefreshRateRegime(RefreshRateManager::RefreshRateRegime::FOCUS_ACTIVE);
        }
    }
}

void RefreshRateManager::toggleInactive() {
    if (_uxMode == RefreshRateManager::UXMode::DESKTOP &&
        getRefreshRateRegime() == RefreshRateManager::RefreshRateRegime::FOCUS_ACTIVE) {
        setRefreshRateRegime(RefreshRateManager::RefreshRateRegime::FOCUS_INACTIVE);
    }
}

void RefreshRateManager::setRefreshRateProfile(RefreshRateManager::RefreshRateProfile refreshRateProfile) {
    if (_refreshRateProfile != refreshRateProfile) {
        _refreshRateProfileSettingLock.withWriteLock([&] {
            _refreshRateProfile = refreshRateProfile;
            _refreshRateProfileSetting.set((int) refreshRateProfile);
        });
        updateRefreshRateController();
    }
}

RefreshRateManager::RefreshRateProfile RefreshRateManager::getRefreshRateProfile() const {
    RefreshRateManager::RefreshRateProfile profile = RefreshRateManager::RefreshRateProfile::REALTIME;

    if (getUXMode() != RefreshRateManager::UXMode::VR) {
        profile =(RefreshRateManager::RefreshRateProfile) _refreshRateProfileSettingLock.resultWithReadLock<int>([&] {
            return _refreshRateProfileSetting.get();
        });
    }

    return profile;
}

RefreshRateManager::RefreshRateRegime RefreshRateManager::getRefreshRateRegime() const {
    if (getUXMode() == RefreshRateManager::UXMode::VR) {
        return RefreshRateManager::RefreshRateRegime::FOCUS_ACTIVE;
    } else {
        return _refreshRateRegime;
    }
}

void RefreshRateManager::setRefreshRateRegime(RefreshRateManager::RefreshRateRegime refreshRateRegime) {
    if (_refreshRateRegime != refreshRateRegime) {
        _refreshRateRegime = refreshRateRegime;
        updateRefreshRateController();
    }

}

void RefreshRateManager::setUXMode(RefreshRateManager::UXMode uxMode) {
    if (_uxMode != uxMode) {
        _uxMode = uxMode;
        updateRefreshRateController();
    }
}

void RefreshRateManager::updateRefreshRateController() const {
    if (_refreshRateOperator) {
        int targetRefreshRate;
        if (_uxMode == RefreshRateManager::UXMode::DESKTOP) {
            targetRefreshRate = REFRESH_RATE_PROFILES[_refreshRateProfile][_refreshRateRegime];
        } else {
            targetRefreshRate = VR_TARGET_RATE;
        }

        _refreshRateOperator(targetRefreshRate);
        _activeRefreshRate = targetRefreshRate;
    }
}

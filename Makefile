TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = DDZHelper

DDZHelper_FILES = Sources/main.m Sources/AppDelegate.m Sources/RootViewController.m Sources/FloatingWindow.m Sources/OCRManager.m Sources/AIManager.m Sources/GameStateManager.m
DDZHelper_FRAMEWORKS = UIKit CoreGraphics QuartzCore AVFoundation ReplayKit
DDZHelper_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -IHeaders
DDZHelper_LDFLAGS = -lc++
DDZHelper_INSTALL_PATH = /Applications
DDZHelper_CODESIGN_FLAGS = -SResources/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

after-DDZHelper-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Applications/DDZHelper.app$(ECHO_END)
	$(ECHO_NOTHING)cp -r Resources/* $(THEOS_STAGING_DIR)/Applications/DDZHelper.app/$(ECHO_END)

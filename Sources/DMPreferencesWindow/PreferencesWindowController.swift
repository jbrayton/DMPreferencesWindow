// MIT License
//
// Copyright © 2018-2020 Darren Mo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa

open class PreferencesWindowController: NSWindowController, PreferencePaneSelectionControllerDelegate {
   // MARK: - Private Properties

   private let lastViewedPreferencePaneController = LastViewedPreferencePaneController()
   private let selectionController: PreferencePaneSelectionController
   private let windowViewController: PreferencesWindowViewController
   private var windowTitleController: PreferencesWindowTitleController

   // MARK: - Initialization

    public init(preferencePaneViewControllers: [NSViewController & PreferencePane & ToolbarItemImageProvider], restorationClass: (any NSWindowRestoration.Type)?) {
        let window = PreferencesWindowController.makeWindow(restorationClass: restorationClass)
        let viewControllers = PreferencePaneViewControllersWithToolbarItemImages(viewControllers: preferencePaneViewControllers)

        let selectionController = ToolbarPreferencePaneSelectionController(window: window,
                                                                         viewControllers: viewControllers)
        let preferencePaneViewControllers = PreferencePaneViewControllers(viewControllers)
        self.selectionController = selectionController
        self.windowViewController = PreferencesWindowViewController(viewControllers: preferencePaneViewControllers)
        self.windowTitleController = PreferencesWindowTitleController(window: window,
                                                                     viewControllers: preferencePaneViewControllers,
                                                                     shouldUsePreferencePaneTitleForWindowTitle: true)

        super.init(window: window)

        let initialSelectedPreferencePaneIdentifier = self.initialSelectedPreferencePaneIdentifier(viewControllers: preferencePaneViewControllers)
        selectionController.selectedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
        windowViewController.visiblePreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
        windowTitleController.selectedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
        lastViewedPreferencePaneController.lastViewedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier

        selectionController.delegate = self
    }

   static func makeWindow(restorationClass: (any NSWindowRestoration.Type)?) -> NSWindow {
      let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
                            styleMask: [.closable, .titled],
                            backing: .buffered,
                            defer: true)
       if let restorationClass {
           window.isRestorable = true
           window.restorationClass = restorationClass
       }
      if #available(macOS 11, *) {
         window.toolbarStyle = .preference
      }
      window.identifier = NSUserInterfaceItemIdentifier(rawValue: "DMPreferencesWindow.window")
      return window
   }

   private init(window: NSWindow,
                selectionController: PreferencePaneSelectionController,
                viewControllers: PreferencePaneViewControllers,
                shouldUsePreferencePaneTitleForWindowTitle: Bool) {
      self.selectionController = selectionController
      self.windowViewController = PreferencesWindowViewController(viewControllers: viewControllers)
      self.windowTitleController = PreferencesWindowTitleController(window: window,
                                                                    viewControllers: viewControllers,
                                                                    shouldUsePreferencePaneTitleForWindowTitle: shouldUsePreferencePaneTitleForWindowTitle)

      super.init(window: window)

      let initialSelectedPreferencePaneIdentifier = self.initialSelectedPreferencePaneIdentifier(viewControllers: viewControllers)
      selectionController.selectedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
      windowViewController.visiblePreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
      windowTitleController.selectedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier
      lastViewedPreferencePaneController.lastViewedPreferencePaneIdentifier = initialSelectedPreferencePaneIdentifier

      selectionController.delegate = self
   }

    required public init?(coder: NSCoder) {
      fatalError("`init(coder:)` has not been implemented.")
   }

   private func initialSelectedPreferencePaneIdentifier(viewControllers: PreferencePaneViewControllers) -> PreferencePaneIdentifier {
      if let lastViewedPreferencePaneIdentifier = lastViewedPreferencePaneController.lastViewedPreferencePaneIdentifier {
         if viewControllers.contains(lastViewedPreferencePaneIdentifier) {
            return lastViewedPreferencePaneIdentifier
         }
      }

      return viewControllers.first!.preferencePaneIdentifier
   }

   // MARK: - Showing the Window

   public var hasBeenShown = false

   open override func showWindow(_ sender: Any?) {
      super.showWindow(sender)

      if !hasBeenShown {
         hasBeenShown = true

         if let window = window {
            window.contentViewController = windowViewController
            window.makeFirstResponder(nil)
            window.layoutIfNeeded()
            window.center()
         }
      }
   }

   public func showWindow(selecting preferencePaneIdentifier: PreferencePaneIdentifier) {
      selectionController.selectedPreferencePaneIdentifier = preferencePaneIdentifier
      preferencePaneSelectionControllerDidChangeSelectedPreferencePaneIdentifier(selectionController)

      showWindow(nil)
   }

   // MARK: - Responding to Selected Preference Pane Identifier Changes

   func preferencePaneSelectionControllerDidChangeSelectedPreferencePaneIdentifier(_ selectionController: PreferencePaneSelectionController) {
      let selectedPreferencePaneIdentifier = selectionController.selectedPreferencePaneIdentifier

      windowViewController.setVisiblePreferencePaneIdentifier(selectedPreferencePaneIdentifier,
                                                              animated: true)
      windowTitleController.selectedPreferencePaneIdentifier = selectedPreferencePaneIdentifier
      lastViewedPreferencePaneController.lastViewedPreferencePaneIdentifier = selectedPreferencePaneIdentifier
   }
}

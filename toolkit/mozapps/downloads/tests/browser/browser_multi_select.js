/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Download Manager UI Test Code.
 *
 * The Initial Developer of the Original Code is
 * Edward Lee <edward.lee@engineering.uiuc.edu>.
 * Portions created by the Initial Developer are Copyright (C) 2008
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

/**
 * Test bug 228842 to make sure multiple selections work in the download
 * manager by making sure commands work as expected for both single and doubly
 * selected items.
 */

function test()
{
  let dm = Cc["@mozilla.org/download-manager;1"].
           getService(Ci.nsIDownloadManager);
  let db = dm.DBConnection;

  // Empty any old downloads
  db.executeSimpleSQL("DELETE FROM moz_downloads");

  let stmt = db.createStatement(
    "INSERT INTO moz_downloads (source, state, target, referrer) " +
    "VALUES (?1, ?2, ?3, ?4)");

  try {
    for each (let site in ["ed.agadak.net", "mozilla.org", "mozilla.com", "mozilla.net"]) {
      let file = Cc["@mozilla.org/file/directory_service;1"].
        getService(Ci.nsIProperties).get("TmpD", Ci.nsIFile);
      file.append(site);
      let fileSpec = Cc["@mozilla.org/network/io-service;1"].
        getService(Ci.nsIIOService).newFileURI(file).spec;

      stmt.bindStringParameter(0, "http://" + site + "/file");
      stmt.bindInt32Parameter(1, dm.DOWNLOAD_FINISHED);
      stmt.bindStringParameter(2, fileSpec);
      stmt.bindStringParameter(3, "http://referrer/");

      // Add it!
      stmt.execute();
    }
  }
  finally {
    stmt.reset();
    stmt.finalize();
  }

  // Close the UI if necessary
  let wm = Cc["@mozilla.org/appshell/window-mediator;1"].
           getService(Ci.nsIWindowMediator);
  let win = wm.getMostRecentWindow("Download:Manager");
  if (win) win.close();

  let obs = Cc["@mozilla.org/observer-service;1"].
            getService(Ci.nsIObserverService);
  const DLMGR_UI_DONE = "download-manager-ui-done";

  let testPhase = 0;
  let testObs = {
    observe: function(aSubject, aTopic, aData) {
      if (aTopic != DLMGR_UI_DONE)
        return;

      let win = aSubject.QueryInterface(Ci.nsIDOMWindow);
      let $ = function(aId) win.document.getElementById(aId);
      let downloadView = $("downloadView");

      // Default test/check for invocations
      let invokeCount = 0;
      let counter = function() invokeCount++;

      // Accessors for returning a value for various properties
      let getItems = function() downloadView.itemCount;
      let getSelected = function() downloadView.selectedCount;
      let getClipboard = function() {
        let clip = Cc["@mozilla.org/widget/clipboard;1"].
                   getService(Ci.nsIClipboard);
        let trans = Cc["@mozilla.org/widget/transferable;1"].
                    createInstance(Ci.nsITransferable);
        trans.addDataFlavor("text/unicode");
        clip.getData(trans, clip.kGlobalClipboard);
        let str = {};
        let strLen = {};
        trans.getTransferData("text/unicode", str, strLen);
        return str.value.QueryInterface(Ci.nsISupportsString).data.
          substring(0, strLen.value / 2);
      };

      // Array of tests that consist of the command name, download manager
      // function to temporarily replace, method to use in its place, value to
      // use when checking correctness
      let commandTests = [
        ["pause", "pauseDownload", counter, counter],
        ["resume", "resumeDownload", counter, counter],
        ["cancel", "cancelDownload", counter, counter],
        ["open", "openDownload", counter, counter],
        ["show", "showDownload", counter, counter],
        ["retry", "retryDownload", counter, counter],
        ["openReferrer", "openReferrer", counter, counter],
        ["copyLocation", null, null, getClipboard],
        ["removeFromList", null, null, getItems],
        ["selectAll", null, null, getSelected],
      ];

      // All the expected results for both single and double selections
      let allExpected = {
        single: {
          pause: [0, "Paused no downloads"],
          resume: [0, "Resumed no downloads"],
          cancel: [0, "Canceled no downloads"],
          open: [0, "Opened no downloads"],
          show: [0, "Showed no downloads"],
          retry: [1, "Retried one download"],
          openReferrer: [1, "Opened one referrer"],
          copyLocation: ["http://ed.agadak.net/file", "Copied one location"],
          removeFromList: [3, "Removed one downloads, remaining 3"],
          selectAll: [3, "Selected all 3 remaining downloads"],
        },
        double: {
          pause: [0, "Paused neither download"],
          resume: [0, "Resumed neither download"],
          cancel: [0, "Canceled neither download"],
          open: [0, "Opened neither download"],
          show: [0, "Showed neither download"],
          retry: [2, "Retried both downloads"],
          openReferrer: [2, "Opened both referrers"],
          copyLocation: ["http://mozilla.org/file\nhttp://mozilla.com/file", "Copied both locations"],
          removeFromList: [1, "Removed both downloads, remaining 1"],
          selectAll: [1, "Selected the 1 remaining download"],
        },
      };

      // Run two tests: single selected, double selected
      for each (let whichTest in ["single", "double"]) {
        let expected = allExpected[whichTest];

        // Select the first download
        downloadView.selectedIndex = 0;

        // Select 2 downloads for double
        if (whichTest == "double")
          EventUtils.synthesizeKey("VK_DOWN", { shiftKey: true }, win);

        for each (let [command, func, test, value] in commandTests) {
          // Make a copy of the original function and replace it with a test
          let copy;
          [copy, win[func]] = [win[func], test];

          // Run the command from the menu
          $("menuitem_" + command).doCommand();

          // Make sure the value is as expected
          let [correct, message] = expected[command];
          ok(value() == correct, message);

          // Restore original values
          invokeCount = 0;
          win[func] = copy;
        }
      }

      // We're done!
      obs.removeObserver(testObs, DLMGR_UI_DONE);
      finish();
    }
  };
  obs.addObserver(testObs, DLMGR_UI_DONE, false);
 
  // Show the Download Manager UI
  Cc["@mozilla.org/download-manager-ui;1"].
  getService(Ci.nsIDownloadManagerUI).show();

  waitForExplicitFinish();
}

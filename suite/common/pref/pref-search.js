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
 * The Original Code is Mozilla Communicator client code, released
 * March 31, 1998.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998-1999
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Robert John Churchill <rjc@netscape.com>
 *   Mark Olson <maolson@earthlink.net>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
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

function Startup()
{
  var engineList = document.getElementById("engineList");
  // Need to set ref attribute once overlay has loaded
  engineList.setAttribute("ref", "NC:SearchEngineRoot");
  // Due to a bug in the internet search service, the first time
  // ref is set only one menuitem is built, so force a rebuild
  engineList.builder.rebuild();

  // Since the menulist starts off empty it has no selected item
  // so try and set it to the preference value.
  var pref = document.getElementById(engineList.getAttribute("preference"));
  engineList.value = pref.value;

  // nothing is selected
  if (!engineList.selectedItem)
  {
    var name = document.getElementById("browser.search.defaultenginename").value;
    var selectedItem = engineList.getElementsByAttribute("label", name).item(0);
 
    if (selectedItem)
    {
      // select a locale-dependent predefined search engine
      // in absence of a user default
      engineList.selectedItem = selectedItem;
    }
    else
    {
      // select the first listed search engine
      engineList.selectedIndex = 0;
    }
    pref.value = engineList.value;
  }
}

/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * The contents of this file are subject to the Netscape Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/NPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code is mozilla.org code.
 *
 * The Initial Developer of the Original Code is Netscape
 * Communications Corporation.  Portions created by Netscape are
 * Copyright (C) 1998 Netscape Communications Corporation. All
 * Rights Reserved.
 *
 * Author: Eric D Vaughan (evaughan@netscape.com)
 * Contributor(s): 
 */

#ifndef _nsHTMLFormControlAccessible_H_
#define _nsHTMLFormControlAccessible_H_

#include "nsGenericAccessible.h"

class nsICheckboxControlFrame;

/* Accessible for supporting for controls
 * supports:
 * - walking up to get name from label
 * - support basic state
 */
class nsHTMLFormControlAccessible : public nsLeafDOMAccessible
{

public:
  nsHTMLFormControlAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccName(PRUnichar **_retval); 
  NS_IMETHOD GetAccState(PRUint32 *_retval); 

protected:
  NS_IMETHODIMP AppendLabelFor(nsIContent *aLookNode, nsAReadableString *aId, nsAWritableString *aLabel);
};

class nsHTMLCheckboxAccessible : public nsHTMLFormControlAccessible
{

public:
  nsHTMLCheckboxAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccRole(PRUint32 *_retval); 
  NS_IMETHOD GetAccNumActions(PRUint8 *_retval);
  NS_IMETHOD GetAccActionName(PRUint8 index, PRUnichar **_retval);
  NS_IMETHOD AccDoAction(PRUint8 index);
};

class nsHTMLRadioButtonAccessible : public nsHTMLFormControlAccessible
{

public:
  nsHTMLRadioButtonAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccRole(PRUint32 *_retval); 
  NS_IMETHOD GetAccNumActions(PRUint8 *_retval);
  NS_IMETHOD GetAccActionName(PRUint8 index, PRUnichar **_retval);
  NS_IMETHOD AccDoAction(PRUint8 index);
};

class nsHTMLButtonAccessible : public nsHTMLFormControlAccessible
{

public:
  nsHTMLButtonAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccRole(PRUint32 *_retval); 
  NS_IMETHOD GetAccName(PRUnichar **_retval); 
  NS_IMETHOD GetAccNumActions(PRUint8 *_retval);
  NS_IMETHOD GetAccActionName(PRUint8 index, PRUnichar **_retval);
  NS_IMETHOD AccDoAction(PRUint8 index);
};

class nsHTML4ButtonAccessible : public nsDOMAccessible
{

public:
  nsHTML4ButtonAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccRole(PRUint32 *_retval); 
  NS_IMETHOD GetAccName(PRUnichar **_retval); 
  NS_IMETHOD GetAccState(PRUint32 *_retval);
  NS_IMETHOD GetAccNumActions(PRUint8 *_retval);
  NS_IMETHOD GetAccActionName(PRUint8 index, PRUnichar **_retval);
  NS_IMETHOD AccDoAction(PRUint8 index);
};


class nsHTMLTextFieldAccessible : public nsHTMLFormControlAccessible
{
public:
  nsHTMLTextFieldAccessible(nsIPresShell* aShell, nsIDOMNode* aNode);
  NS_IMETHOD GetAccRole(PRUint32 *_retval); 
  NS_IMETHOD GetAccValue(PRUnichar **_retval); 
  NS_IMETHOD GetAccState(PRUint32 *_retval);
};

#endif  

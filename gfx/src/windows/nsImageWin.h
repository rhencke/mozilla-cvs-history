/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * The contents of this file are subject to the Netscape Public License
 * Version 1.0 (the "NPL"); you may not use this file except in
 * compliance with the NPL.  You may obtain a copy of the NPL at
 * http://www.mozilla.org/NPL/
 *
 * Software distributed under the NPL is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the NPL
 * for the specific language governing rights and limitations under the
 * NPL.
 *
 * The Initial Developer of this code under the NPL is Netscape
 * Communications Corporation.  Portions created by Netscape are
 * Copyright (C) 1998 Netscape Communications Corporation.  All Rights
 * Reserved.
 */

#ifndef nsImageWin_h___
#define nsImageWin_h___

#include "nsIImage.h"

class nsImageWin : public nsIImage
{
public:
  nsImageWin();
  ~nsImageWin();

  NS_DECL_ISUPPORTS

  virtual PRInt32     GetHeight()         { return mBHead->biHeight; }
  virtual PRInt32     GetWidth()          { return mBHead->biWidth; }
  virtual PRUint8*    GetAlphaBits()      { return mAlphaBits; }
  virtual PRInt32     GetAlphaLineStride(){ return mBHead->biWidth; }
  virtual PRUint8*    GetBits()           { return mImageBits; }
          PRIntn      GetSizeHeader()     {return sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * mNumPalleteColors;}
  virtual PRInt32     GetLineStride()     {return mRowBytes; }
          PRIntn      GetSizeImage()                 { return mSizeImage; }
  virtual PRBool      Draw(nsDrawingSurface aSurface, PRInt32 aX, PRInt32 aY, PRInt32 aWidth, PRInt32 aHeight);
  virtual PRBool      Draw(nsDrawingSurface aSurface, PRInt32 aSX, PRInt32 aSY, PRInt32 aSWidth, PRInt32 aSHeight,
                                  PRInt32 aDX, PRInt32 aDY, PRInt32 aDWidth, PRInt32 aDHeight);
  virtual nsColorMap* GetColorMap() {return mColorMap;}
  virtual void        ImageUpdated(PRUint8 aFlags, nsRect *aUpdateRect);
  virtual nsresult    Init(PRInt32 aWidth, PRInt32 aHeight, PRInt32 aDepth, nsMaskRequirements aMaskRequirements);
  virtual PRBool      IsOptimized()       { return mIsOptimized; }
          PRBool      MakePalette();
  virtual nsresult    Optimize(nsDrawingSurface aSurface);
          PRBool      SetSystemPalette(HDC* aHdc);
          PRUintn     UsePalette(HDC* aHdc, PRBool bBackground = PR_FALSE);
          void        TestFillBits();
          PRInt32     TestSpeedBits(nsDrawingSurface aSurface, PRInt32 aX, PRInt32 aY, PRInt32 aWidth, PRInt32 aHeight);

private:
  void CleanUp(PRBool aCleanUpAll);
  void ComputePaletteSize(PRIntn aBitCount);
  void ComputeMetrics();

  PRInt8              mNumBytesColor;     // number of bytes per color
  PRInt16             mNumPalleteColors;  // either 8 or 0
  PRInt32             mSizeImage;         // number of bytes
  PRInt32             mRowBytes;          // number of bytes per row
  PRUint8             *mColorTable;       // color table for the bitmap
  LPBYTE              mImageBits;         // starting address of DIB bits
  LPBYTE              mAlphaBits;         // alpha layer if we made one
  PRBool              mIsOptimized;       // Have we turned our DIB into a GDI?
  nsColorMap          *mColorMap;         // Redundant with mColorTable, but necessary
                                          // for Set/GetColorMap
  HPALETTE            mHPalette;
  HBITMAP             mHBitmap;           // the GDI bitmap
  static HDC          mOptimizeDC;        // optimized DC for hbitmap
  LPBITMAPINFOHEADER  mBHead;             // BITMAPINFOHEADER
};


/* TODO
===================================
1.)  Share teh offscreen DC between other nsImageWin objects if nessasary



*/
#endif

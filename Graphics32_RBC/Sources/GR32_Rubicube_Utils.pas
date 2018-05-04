unit GR32_Rubicube_Utils;

interface

uses
    GR32
  , GR32_Polygons
  , GR32_VectorUtils
  , VCL.Graphics                //  TColor
  , System.Classes              //  TList
  ;

const
  Pi   = 3.141592653589793; // 270. derece
  Pi_1 = 1.570796326794897; // 180. derece
  Pi_3 = 4.712388980384690; // 90. derece...
  Pi_4 = 6.283185307179586; // Bu �zel hesaplamalar i�in kullan�lan Pi'nin 2. kat�d�r...
  Pi_004 = Pi_4 * 0.01;     // => 0.06283185307179586

type
  TPiOfsetTipi = (Pi_0, Pi_90, Pi_180, Pi_270);
  TPiOfsetTipi_Helper = record helper for TPiOfsetTipi
    public
      function ToSingle: Single;
  end;
const
  PiOfset : array [low(TPiOfsetTipi)..High(TPiOfsetTipi)] of Single = ( 4.71238898038469  //   0. derece (Veya 360. derece)
                                                                      , 0.0               //  90. derece
                                                                      , 1.570796326794897 // 180. derece
                                                                      , 3.141592653589793 // 270. derece
                                                                      );
type                                                                    //            0          1              0          1    //
  TGR32WidgetFillStyle      = (wfsWinding, wfsAlternatif );     //  TPolyFillMode; // (pfAlternate, pfWinding, pfEvenOdd = 0, pfNonZero); "= 0" atamas� yap�lm�� dolay�s�yla object inspectorde ��km�yor, o nedenle ek bir set tan�mland�.
  TGR32WidgetVerticalPos    = (wvpNone, wvpTop, wvpBottom);    //  Dikey konumland�rma bilgisi i�in...
  TGR32WidgetHorizontalPos  = (whpNone, whpLeft, whpRight);  //  Yatay konumland�rma bilgisi i�in
  TFontPos                  = (fpTopLeft, fpTopCenter, fpTopRight, fpCenterLeft, fpCenterCenter, fpCenterRight, fpBottomLeft, fpBottomCenter, fpBottomRight);
  TColor_Helper = record Helper for TColor
    public
      function ToColor32: TColor32;
  end;
  TListHelper = class helper for TList
    public
      procedure Flush; // Listenin i�indeki TObject soyundan gelen nesneleri free etmeye yarar... Clear'dan daha etkilidir !
  end;
  TRenderHelper = class helper for TPolygonRenderer32VPR // TPolygonRenderer32
    public
      function ArrayOfFloat(Values: array of TFloat): TArrayOfFloat;
      function Kare(aMerkez: TFloatPoint; aKenar: Single): TArrayOfFloatPoint;
      function Dikdortgen(aMerkez: TFloatPoint; aWidth, aHeight: Single): TArrayOfFloatPoint;
      function DikdortgenOval(aMerkez: TFloatPoint; aWidth, aHeight: Single; YariCap: Single = 8): TArrayOfFloatPoint;
      function DikDortgenCizgi(aMerkez: TFloatPoint; aWidth, aHeight, aKalinlik: Single; aStyle: TPenStyle = psSolid): TArrayOfArrayOfFloatPoint;
      function Cizgi(aXY, aWH: TFloatPoint; aKalinlik: Single; aStyle: TPenStyle = psSolid): TArrayOfArrayOfFloatPoint;
      function CizgiDama(aXY, aWH: TFloatPoint; aKalinlik: Single; aDamaSize: Single): TArrayOfArrayOfFloatPoint;
      function Daire(aMerkez: TFloatPoint; aYariCap: Single): TArrayOfFloatPoint;
      function Pasta(aMerkez: TFloatPoint; aYariCap: Single; aYuzde: Single; aOfset: TPiOfsetTipi = Pi_0): TArrayOfFloatPoint;
      procedure SekilBas(aRenk: TColor32; const aPoints: TArrayOfFloatPoint); overload; // Filler eklenecek
      procedure SekilBas(aRenk: TColor32; const aPoints: TArrayOfArrayOfFloatPoint); overload; // Filler eklenecek
      procedure YaziBas(X, Y: Integer; aString: String; aColor: TColor = cldefault; aFontSize: Integer = 0; aFontName: String = ''; aFontPos: TFontPos = fpCenterCenter; aFontStyle: TFontStyles = []; aAntiAliased: Boolean = False); overload;
      procedure YaziBas(aRect: TRect; aString: String; aColor: TColor = cldefault; aFontSize: Integer = 0; aFontName: String = ''; aFontPos: TFontPos = fpCenterCenter; aFontStyle: TFontStyles = []; aAntiAliased: Boolean = False); overload;
  end;

implementation

uses
    System.Types    //  TSize
  , System.SysUtils //  FreeAndNil
  ;

{ TRenderHelper }

function TRenderHelper.Daire(aMerkez: TFloatPoint; aYariCap: Single): TArrayOfFloatPoint;
begin
  Result := Circle(aMerkez, aYariCap);
end;

function TRenderHelper.Dikdortgen(aMerkez: TFloatPoint; aWidth, aHeight: Single): TArrayOfFloatPoint;
var
  R: TFloatRect;
begin
  R.Left   := aMerkez.X - (aWidth * 0.5);
  R.Right  := aMerkez.X + (aWidth * 0.5);
  R.Top    := aMerkez.Y - (aHeight * 0.5);
  R.Bottom := aMerkez.Y + (aHeight * 0.5);
  Result := Rectangle(R);
end;

function TRenderHelper.DikdortgenOval(aMerkez: TFloatPoint; aWidth, aHeight, YariCap: Single): TArrayOfFloatPoint;
var
  R: TFloatRect;
begin
  R.Left   := aMerkez.X - (aWidth * 0.5);
  R.Right  := aMerkez.X + (aWidth * 0.5);
  R.Top    := aMerkez.Y - (aHeight * 0.5);
  R.Bottom := aMerkez.Y + (aHeight * 0.5);
  Result := RoundRect(R, YariCap);
end;

function TRenderHelper.ArrayOfFloat(Values: array of TFloat): TArrayOfFloat;
var
  Index: Integer;
begin
  SetLength(Result, Length(Values));
  for Index := Low(Values) to High(Values) do Result[Index] := Values[Index];
end;

function TRenderHelper.DikDortgenCizgi(aMerkez: TFloatPoint; aWidth, aHeight, aKalinlik: Single; aStyle: TPenStyle): TArrayOfArrayOfFloatPoint;
var
  X, Y, W, H, Z: Single;
  Noktalar: TArrayOfFloatPoint;
  AOF: Array of Single; // : TArrayOfFloat;
  Dash, Dot: Single;
begin
  if (aKalinlik < 1)
  or (aWidth < 1)
  or (aHeight < 1)
  then begin
      Result := [];
      Exit;
  end;
  X := aMerkez.X - (aWidth  * 0.5) + (aKalinlik * 0.5);
  Y := aMerkez.Y - (aHeight * 0.5) + (aKalinlik * 0.5);;
  W := aWidth - aKalinlik;
  H := aHeight - aKalinlik;
  SetLength(Noktalar, 5);
  Noktalar[0] := FloatPoint(X, Y);
  Noktalar[1] := FloatPoint(X + W, Y);
  Noktalar[2] := FloatPoint(X + W, Y + H);
  Noktalar[3] := FloatPoint(X, Y + H);
  Noktalar[4] := FloatPoint(X, Y);
  Z := aKalinlik;
  Dash := Z * 3;
  Dot  := Z * 1;
  case aStyle of
       psClear       : Result := [];
       psSolid       : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash                             ])), False, aKalinlik, jsRound, esRound); // BuildPolyline(Noktalar, aKalinlik, jsRound, esRound);
       psDash        : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash                       ])), False, aKalinlik, jsRound, esRound);
       psDot         : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dot , Dash                       ])), False, aKalinlik, jsRound, esRound);
       psDashDot     : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash, Dot, Dash            ])), False, aKalinlik, jsRound, esRound);
       psDashDotDot  : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash, Dot, Dash, Dot, Dash ])), False, aKalinlik, jsRound, esRound);
       psInsideFrame : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash                             ])), False, aKalinlik, jsRound, esRound); // BuildPolyline(Noktalar, aKalinlik, jsBevel, esSquare);
       psUserStyle   : Result := [];
       psAlternate   : Result := [];
  end;
end;

function TRenderHelper.Cizgi(aXY, aWH: TFloatPoint; aKalinlik: Single; aStyle: TPenStyle): TArrayOfArrayOfFloatPoint;
var
  //X, Y, W, H,
  Z: Single;
  Noktalar: TArrayOfFloatPoint;
  Dash, Dot: Single;
begin
  if (aKalinlik < 1) then begin
      Result := [];
      Exit;
  end;
  SetLength(Noktalar, 2);
  Noktalar[0] := FloatPoint(aXY.X, aXY.Y);
  Noktalar[1] := FloatPoint(aWH.X, aWH.Y);
  Z := aKalinlik;
  Dash := Z * 3;
  Dot  := Z * 1;
  case aStyle of
       psClear       : Result := [];
       psSolid       : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash                             ])), False, aKalinlik, jsRound, esRound); // BuildPolyline(Noktalar, aKalinlik, jsRound, esRound);
       psDash        : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash                       ])), False, aKalinlik, jsRound, esRound);
       psDot         : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dot , Dash                       ])), False, aKalinlik, jsRound, esRound);
       psDashDot     : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash, Dot, Dash            ])), False, aKalinlik, jsRound, esRound);
       psDashDotDot  : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash, Dash, Dot, Dash, Dot, Dash ])), False, aKalinlik, jsRound, esRound);
       psInsideFrame : Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([Dash                             ])), False, aKalinlik, jsRound, esRound); // BuildPolyline(Noktalar, aKalinlik, jsBevel, esSquare);
       psUserStyle   : Result := [];
       psAlternate   : Result := [];
  end;
end;

function TRenderHelper.CizgiDama(aXY, aWH: TFloatPoint; aKalinlik, aDamaSize: Single): TArrayOfArrayOfFloatPoint;
var
  //X, Y, W, H,
  Z: Single;
  Noktalar: TArrayOfFloatPoint;
  Dash, Dot: Single;
begin
  if (aKalinlik < 1)
  or (aDamaSize < 1)
  then begin
      Result := [];
      Exit;
  end;
  SetLength(Noktalar, 2);
  Noktalar[0] := FloatPoint(aXY.X, aXY.Y);
  Noktalar[1] := FloatPoint(aWH.X, aWH.Y);
  Z := aKalinlik;
  Dash := Z * 3;
  Dot  := Z * 1;
  Result := BuildPolyPolyline(BuildDashedLine(Noktalar, ArrayOfFloat([aDamaSize, aDamaSize])), False, aKalinlik, jsRound, esRound); // BuildPolyline(Noktalar, aKalinlik, jsRound, esRound);
end;

function TRenderHelper.Kare(aMerkez: TFloatPoint; aKenar: Single): TArrayOfFloatPoint;
var
  R: TFloatRect;
begin
  R.Top    := aMerkez.Y - (aKenar * 0.5);
  R.Bottom := aMerkez.Y + (aKenar * 0.5);
  R.Left   := aMerkez.X - (aKenar * 0.5);
  R.Right  := aMerkez.X + (aKenar * 0.5);
  Result := Rectangle(R);
end;

function TRenderHelper.Pasta(aMerkez: TFloatPoint; aYariCap, aYuzde: Single; aOfset: TPiOfsetTipi = Pi_0): TArrayOfFloatPoint;
begin
  Result  := Pie ( { P}       aMerkez          // Merkez Noktas�
                 , { Radius } aYariCap         // Yar��ap
                 , { Angle }  aYuzde * Pi_004  // istenen a��... 100 �zrinden...
                 , { Offset } PiOfset[aOfset]  // S�f�r�nc� a��n�n hangi derecede ba�layaca�� bilgisidir. 0 = 90, Pi/2 = 180, Pi = 270 ve Pi/2*3 = 360 derecedir...
                 , { Steps }  360              // Yuvarla��n kenar�ndaki poligon say�s�d�r...
                 );
end;

procedure TRenderHelper.SekilBas(aRenk: TColor32; const aPoints: TArrayOfArrayOfFloatPoint);
begin
  Color := aRenk;
  PolyPolygonFS(aPoints, FloatRect(Self.Bitmap.ClipRect));
end;

procedure TRenderHelper.SekilBas(aRenk: TColor32; const aPoints: TArrayOfFloatPoint);
begin
  Color := aRenk;
  PolyPolygonFS(PolyPolygon(aPoints), FloatRect(Self.Bitmap.ClipRect));
end;

procedure TRenderHelper.YaziBas ( aRect: TRect
                                ; aString: String
                                ; aColor: TColor
                                ; aFontSize: Integer
                                ; aFontName: String
                                ; aFontPos: TFontPos
                                ; aFontStyle: TFontStyles
                                ; aAntiAliased: Boolean);
var
  RX, RY, RW, RH, RW2, RH2: Integer;
  TX, TY, TW, TH, TW2, TH2: Integer;
begin
  with  Self.Bitmap do begin
        if (aColor <> 0)      then Font.Color := aColor;
        if (aFontSize <> 0)   then Font.Size := aFontSize;
        if (aFontName <> '')  then Font.Name := aFontName;
        Font.Style := aFontStyle;

        RX := aRect.Left;
        RY := aRect.Top;
        RW := aRect.Right;         RW2 := (RW div 2) + (RX div 2);
        RH := aRect.Bottom;        RH2 := (RH div 2) + (RY div 2);

        TX := 0;
        TY := 0;
        TW := TextWidth(aString);  TW2 := (TW div 2);
        TH := TextHeight(aString); TH2 := (TH div 2);

        case aFontPos of
             fpTopLeft      : begin TX := RX       ; TY := RY       ; end; // ok
             fpTopCenter    : begin TX := RW2 - TW2; TY := RY       ; end; // ok
             fpTopRight     : begin TX := RW  - TW ; TY := RY       ; end; // ok

             fpCenterLeft   : begin TX := RX       ; TY := RH2 - TH2; end; // ok
             fpCenterCenter : begin TX := RW2 - TW2; TY := RH2 - TH2; end; // ok
             fpCenterRight  : begin TX := RW  - TW ; TY := RH2 - TH2; end; // ok

             fpBottomLeft   : begin TX := RX       ; TY := RH  - TH ; end; // ok
             fpBottomCenter : begin TX := RW2 - TW2; TY := RH  - TH ; end; // ok
             fpBottomRight  : begin TX := RW  - TW ; TY := RH  - TH ; end; // ok
        end;

        case aAntiAliased of
          True : RenderText(TX, TY, aString, 1, Color32(aColor) );
          False: TextOut(TX, TY, aString);
        end;
  end;
end;

procedure TRenderHelper.YaziBas(X, Y: Integer; aString: String; aColor: TColor; aFontSize: Integer; aFontName: String; aFontPos: TFontPos; aFontStyle: TFontStyles; aAntiAliased: Boolean);
var
  W, H, W2, H2: Integer;
  Q: Integer; //  Left - Right
  R: Integer; //  Top  - Bottom
begin
  with  Self.Bitmap do begin
        if (aColor <> 0)      then Font.Color := aColor;
        if (aFontSize <> 0)   then Font.Size := aFontSize;
        if (aFontName <> '')  then Font.Name := aFontName;
        Font.Style := aFontStyle;

        Q := 0;
        R := 0;
        W := TextWidth(aString);  W2 := (W div 2);
        H := TextHeight(aString); H2 := (H div 2);

        case aFontPos of
             fpTopLeft      : begin Q := X - W  ; R := Y - H  ; end; // ok
             fpTopCenter    : begin Q := X - W2 ; R := Y - H  ; end; // ok
             fpTopRight     : begin Q := X      ; R := Y - H  ; end; // ok
             fpCenterLeft   : begin Q := X - W  ; R := Y - H2 ; end; // ok
             fpCenterCenter : begin Q := X - W2 ; R := Y - H2 ; end; // ok
             fpCenterRight  : begin Q := X      ; R := Y - H2 ; end; // ok
             fpBottomLeft   : begin Q := X - W  ; R := Y      ; end; // ok
             fpBottomCenter : begin Q := X - W2 ; R := Y      ; end; // ok
             fpBottomRight  : begin Q := X      ; R := Y      ; end; // ok
        end;
        case aAntiAliased of
          True : RenderText(Q, R, aString, 1, Color32(aColor) );
          False: TextOut(Q, R, aString);
        end;
  end;
end;

{ TPiOfsetTipi_Helper }

function TPiOfsetTipi_Helper.ToSingle: Single;
begin
  Result := PiOfset[Self];
end;

{ TColor_Helper }

function TColor_Helper.ToColor32: TColor32;
begin
  Result := Color32(Self);
end;

{ TListHelper }

procedure TListHelper.Flush;
var
  I: Integer;
begin
  for I := Self.Count - 1 downto 0 do begin
      TObject( Self[I] ).Free;
      Self.Delete( I );
  end;
end;

end.

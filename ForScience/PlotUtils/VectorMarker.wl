(* ::Package:: *)

VectorMarker;


Begin["`Private`"]


BuildAction[Clear@GlyphMetrics]


GlyphMetrics[Style[s_String]]:=GlyphMetrics[s]
GlyphMetrics[s_String]:=GlyphMetrics[Style[s,FontFamily->"Arial"]]
GlyphMetrics[s:Style[_String,___]]:=GlyphMetrics[s]=Let[
  {
    graphics=First@ImportString[ExportString[s,"PDF"],"PDF"],
    discretized=DiscretizeGraphics@graphics,
    curves=Cases[graphics,_FilledCurve,All],
    filled=Thread@*GeometricFunctions`DecodeFilledCurve/@curves,
    holes=Area@DiscretizeGraphics@filled>1.01Area@discretized,
    plotRange=PlotRange@graphics,
    bounds=RegionBounds@discretized,
    centroid=RegionCentroid@discretized
  },
  <|"plotRange"->plotRange,"bounds"->bounds,"primitives"->curves,"filledPrimitives"->filled,"hasHoles"->holes,"centroid"->centroid|>
]


$DefaultMarkers=Graphics`PlotMarkers[][[All,1]];
$PreciseMarkers={"+","\[Times]","*","\[CirclePlus]","\[CircleTimes]","\[CircleDot]"};


$DefaultGlyphMetrics=BuildTimeEvaluate["DefaultPlotMarkers",AssociationMap[GlyphMetrics]@Join[$DefaultMarkers,$PreciseMarkers],"CacheID"->1];
KeyValueMap[(GlyphMetrics[#]=#2)&]@$DefaultGlyphMetrics;


PolygonMetrics[n_Integer,th_]:=PolygonMetrics[n,th]=Let[
  {
    ph0=Pi(1+1/n)+th+If[n<0,-Pi/n,0],
    polygon=Polygon@N@Array[
      With[
        {ph=2Pi #/n},
        {Sin[ph0+ph],Cos[ph0+ph]}
      ]&,
      Abs@n
    ],
    bounds=RegionBounds@polygon
  },
  <|"plotRange"->1.5{{-1,1},{-1,1}},"bounds"->bounds,"primitives"->polygon,"filledPrimitives"->polygon,"hasHoles"->False,"centroid"->{0,0}|>
]


$EmptyFilledMapping=<|"\[EmptyCircle]"->"\[FilledCircle]","\[EmptyDiamond]"->"\[FilledDiamond]","\[EmptyDownTriangle]"->"\[FilledDownTriangle]","\[EmptyRectangle]"->"\[FilledRectangle]","\[EmptySmallCircle]"->"\[FilledSmallCircle]","\[EmptySmallSquare]"->"\[FilledSmallSquare]","\[EmptySquare]"->"\[FilledSquare]","\[EmptyUpTriangle]"->"\[FilledUpTriangle]","\[EmptyVerySmallSquare]"->"\[FilledVerySmallSquare]"|>;


ResolvePositionSpec[Right]:={1,0}
ResolvePositionSpec[Left]:={-1,0}
ResolvePositionSpec[Top]:={0,1}
ResolvePositionSpec[Bottom]:={0,-1}
ResolvePositionSpec[p:{_?NumericQ,_?NumericQ}]:=p
ResolvePositionSpec[l_List]:=Total[ResolvePositionSpec/@l]


Options[VectorMarker]={
  Background->White,
  "MakeEmpty"->Automatic,
  Thickness->Inherited,
  AlignmentPoint->Automatic,
  JoinForm->{"Miter",20},
  EdgeForm->Automatic,
  FaceForm->Automatic
};


VectorMarker[Automatic,o:OptionsPattern[]]:=
  VectorMarker[{Automatic,15},o]
VectorMarker[{Automatic,s_},o:OptionsPattern[]]:=
  VectorMarker[{#,s},o]&/@$DefaultMarkers
VectorMarker["Precise",o:OptionsPattern[]]:=
  VectorMarker[{"Precise",20},o]
VectorMarker[{"Precise",s_},o:OptionsPattern[]]:=
  VectorMarker[{Style[#,Bold],s},o,Background->None]&/@$PreciseMarkers
VectorMarker[Polygon,o:OptionsPattern[]]:=
  VectorMarker[{Polygon,15},o]
VectorMarker[{Polygon,s_},o:OptionsPattern[]]:=
  VectorMarker[{Polygon@#,s},o]&/@{3,-3,4,-4,5,-5,6,-6}
VectorMarker[Polygon[n_Integer,th_:0]|{Polygon[n_Integer,th_:0],size_?NumericQ},opts:OptionsPattern[]]:=VectorMarker[PolygonMetrics[n,th],size,opts]
VectorMarker[(spec:s_String|Style[s_String,styles___])|{spec:s_String|Style[s_String,styles___],size_?NumericQ},opts:OptionsPattern[]]:=If[
  OptionValue["MakeEmpty"]=!=False&&KeyMemberQ[$EmptyFilledMapping,s],
  VectorMarker[
    GlyphMetrics[Style[$EmptyFilledMapping[s],styles]],
    size,
    "MakeEmpty"->True,
    opts
  ],
  VectorMarker[
    GlyphMetrics[spec],
    size,
    opts
  ]
]
VectorMarker[specs_List,opts:OptionsPattern[]]:=VectorMarker[#,opts]&/@specs
VectorMarker[metrics_Association,size:_?NumericQ:10,OptionsPattern[]]:=Let[
  {
    makeEmpty=OptionValue["MakeEmpty"]/.{Full->!metrics["hasHoles"],Automatic->False,All->True},
    background=OptionValue[Background],
    alignmentPoint=OptionValue[AlignmentPoint]/.{
      Automatic->metrics["centroid"],
      ap_:>Mean/@metrics["bounds"]+0.5*Abs[Subtract@@@metrics["bounds"]]*ResolvePositionSpec[ap]
    },
    bgPrimitives=If[makeEmpty||background===None,Nothing,{Opacity@Inherited,EdgeForm@None,background,metrics["filledPrimitives"]}],
    faceForm=Which[
      !makeEmpty,
      Replace[
        OptionValue[FaceForm],
        {
          None->FaceForm@None,
          Automatic|Directive[d___]|{d___}|d2_:>
            FaceForm@{
              RGBColor@Inherited,
              Opacity@Inherited,
              d,
              d2
            }
        }
      ],
      background===None,
      FaceForm@None,
      True,
      FaceForm@{Opacity@Inherited,background}
    ],
    edgeForm=Replace[
      OptionValue[EdgeForm],
      {
        None|(Automatic/;!makeEmpty):>EdgeForm@None,
        Automatic|All|Directive[d___]|{d___}|d2_:>
          EdgeForm@{
            JoinForm@OptionValue[JoinForm],
            Replace[
              OptionValue[Thickness],
              t:Except[_Thickness|_AbsoluteThickness]:>Thickness@t
            ],
            RGBColor@Inherited,
            Opacity@Inherited,
            d,
            d2
          }
      }
    ]
  },
  {
    Graphics[
      {
        Style@{
          bgPrimitives,
          faceForm,
          edgeForm,
          metrics["primitives"]
        }
      },
      VectorMarker,
      AlignmentPoint->alignmentPoint,
      ImageSize->{Automatic,3size},
      PlotRangeClipping->False,
      PlotRangePadding->Scaled@0.3,
      PlotRange->metrics["plotRange"]
    ],
    size
  }
]
InsertBaseStyles[g_,styles_]:=g/.h_@Inherited:>Directive@@Cases[
  FixedPoint[
    Flatten[Replace[#,Directive[s___]:>{s},1]]&,
    List@@styles
  ],
  Switch[h,
    RGBColor,
    _?ColorQ,
    Thickness,
    (h|AbsoluteThickness)[__],
    Dashing,
    (h|AbsoluteDashing)[__],
    _,
    h[__]
  ]
]


VectorMarker/:Graphics[prim_,VectorMarker,opts___]/;MemberQ[{opts},DefaultBaseStyle->_,All]:=
  VectorMarker[
    InsertBaseStyles[
      Graphics[prim,FilterRules[{opts},Except[DefaultBaseStyle]]],
      OptionValue[GraphicsBox,{opts},DefaultBaseStyle]/.
        {"Graphics",s__}:>{s}
    ],
    Automatic
  ]
VectorMarker/:Inset[VectorMarker[g_Graphics,Automatic],pos_,Automatic,_]:=
  Inset[g,pos]
VectorMarker/:Inset[VectorMarker[g_Graphics,Automatic],pos_]:=
  Inset[g,pos]


If[$VersionNumber<12.0,
  VectorMarker/:Graphics[{styles__,Style[prim_]},VectorMarker,opts___]:=
    VectorMarker[InsertBaseStyles[Graphics[prim,opts],{styles}],Automatic],
  Typeset`MakeBoxes[Inset[Style[Graphics[{Style@prim_},VectorMarker,opts___],sOpts__],pos_,Automatic,_],_,Graphics]/;
    MemberQ[{sOpts},GraphicsBoxOptions->_]:=
      With[
        {
          marker=InsertBaseStyles[
            Graphics[prim,opts],
            OptionValue[GraphicsBox,GraphicsBoxOptions/.{sOpts},DefaultBaseStyle]
          ]
        },
        InsetBox[Evaluate@MakeBoxes[marker,StandardForm],pos]
      ]
]


(* Typesetting of marker-type graphics expression (contains "invalid option" VectorMarker) *)
Unprotect[Graphics];
Graphics/:MakeBoxes[g:Graphics[prim_,VectorMarker,opts___],frm:StandardForm|TraditionalForm]:=Let[
  {
    pPrim=DeleteCases[prim,_@Inherited,All],
    gBoxes=MakeBoxes[
      Graphics[
        pPrim,
        ImageSize->15,
        opts
      ],
      frm
    ]
  },
  InterpretationBox[RowBox@{"VectorMarker","[",gBoxes,"]"},g]
]
Protect[Graphics];


End[]

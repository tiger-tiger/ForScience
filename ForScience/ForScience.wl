(* ::Package:: *)

BeginPackage["ForScience`"]


EndPackage[]


Block[{Notation`AutoLoadNotationPalette=False},
  BeginPackage["ForScience`Util`",{"Notation`"}]
]


(*usage formatting utilities, need to make public before defining, as they're already used in the usage definition*)
FixUsage;
StringEscape;
FormatUsageCase;
FormatUsage;
FormatCode;


Begin["Private`"]


FixUsage[usage_]:=If[StringMatchQ[usage,"\!\("~~__],"","\!\(\)"]<>StringReplace[usage,{p:("\!\(\*"~~__?(StringFreeQ["\*"])~~"\)"):>StringReplace[p,"\n"->""],"\n"->"\n\!\(\)"}]


StringEscape[str_String]:=StringReplace[str,{"\\"->"\\\\","\""->"\\\""}]


FormatUsageCase[str_String]:=StringReplace[
  str,
  RegularExpression@
  "(^|\n)(\\w*)(?P<P>\\[(?:[\\w{}\[Ellipsis],=]|(?P>P))*\\])"
  :>"$1'''$2"
    <>StringReplace["$3",RegularExpression@"\\w+"->"```$0```"]
    <>"'''"
]


FormatDelims="'''"|"```";
FormatCode[str_String]:=FixUsage@FixedPoint[
  StringReplace[
    {
      pre:((___~~Except[WordCharacter])|"")~~b:(WordCharacter)..~~"_"~~s:(WordCharacter)..:>pre<>"\!\(\*SubscriptBox[\""<>StringEscape@b<>"\",\""<>StringEscape@s<>"\"]\)",
      pre___~~"{"~~b__~~"}_{"~~s__~~"}"/;(And@@(StringFreeQ["{"|"}"|"'''"|"```"|"_"]/@{b,s})):>pre<>"\!\(\*SubscriptBox[\""<>StringEscape@b<>"\",\""<>StringEscape@s<>"\"]\)",
      pre___~~"```"~~c__~~"```"/;StringFreeQ[c,FormatDelims]:>pre<>"\!\(\*StyleBox[\""<>StringEscape@c<>"\",\"TI\"]\)",
      pre___~~"'''"~~c__~~"'''"/;StringFreeQ[c,FormatDelims]:>pre<>"\!\(\*StyleBox[\""<>StringEscape@c<>"\",\"MR\"]\)"
    }
  ],
  str
]
FormatUsage=FormatCode@*FormatUsageCase;


End[]


FixUsage::usage=FormatUsage@"fixUsuage[str] fixes usage messages with custom formatting so that they are properly displayed in the front end";
StringEscape::usage=FormatUsage@"StringEscape[str] escapes literal '''\\''' and '''\"''' in ```str```";
FormatUsageCase::usage=FormatUsage@"FormatUsageCase[str] prepares all function calls all the beginning of a line in ```str``` to be formatted nicely by '''FormatCode'''. See also '''FormatUsage'''.";
FormatCode::usage=FormatUsage@"formatCome[str] formats anything wrapped in \!\(\*StyleBox[\"```\",\"MR\"]\) as 'Times Italic' and anything wrapped in \!\(\*StyleBox[\"'''\",\"MR\"]\) as 'Mono Regular'. Also formats subscripts to a_b (written as "<>"\!\(\*StyleBox[\"a_b\",\"MR\"]\) or \!\(\*StyleBox[\"{a}_{b}\",\"MR\"]\).)";
FormatUsage::usage=FormatUsage@"FormatUsage[str] combines the functionalities of '''FormatUsageCase''' and '''FormatCode'''.";

AssignmentWrapper::usage=FormatUsage@"'''{//}_{=}''' works like '''//''', but the ```rhs``` is wrapped around any '''Set'''/'''SetDelayed''' on the ```lhs```. E.g. '''foo=bar{//}_{=}FullForm''' is equivalent to '''FullForm[foo=bar]'''";
MergeRules::usage=FormatUsage@"MergeRules[rule_1,\[Ellipsis]] combines all rules into a single rule, that matches anything any of the rules match and returns the corresponding replacement. Useful e.g. for '''Cases'''";
Let::usage=FormatUsage@"Let[{var_1=expr_1,\[Ellipsis]},expr] works exactly like '''With''', but allows variable definitions to refer to previous ones.";
FunctionError;(*make error symbols public*)
IndexedFunction::usage=FormatUsage@"IndexedFunction[expr,id] works like '''Function[```expr```]''', but only considers Slots/SlotSequences subscripted with ```id``` (e.g. '''{#}_{1}''' or '''{##3}_{f}'''. Can also be entered using a subscripted '''&''' (e.g. '''{&}_{1}''', this can be entered using \[AliasIndicator]cf\[AliasIndicator])";
Private`ProcessingAutoSlot=True;(*disable AutoSlot related parsing while setting usage messages. Needed when loading this multiple times*)
\[Bullet]::usage=FormatUsage@"\[Bullet] works analogously to '''#''', but doesn't require an eclosing '''&'''. Slots are only filled on the topmost level. E.g. '''f[\[Bullet], g[\[Bullet]]][3]'''\[RightArrow]'''f[3,g[\[Bullet]]]'''. Can also use '''\[Bullet]'''```n``` and '''\[Bullet]'''```name```, analogous to '''#'''. See also '''\[Bullet]\[Bullet]''' Enter \[Bullet] s '''\\[Bullet]''' or '''ALT+7'''.";
\[Bullet]\[Bullet]::usage=FormatUsage@"\[Bullet]\[Bullet] works the same as \[Bullet], but is analogue to ##. Can also use '''\[Bullet]'''```n```, analogous to ```##```. Enter \[Bullet] as '''\\[Bullet]''' or '''ALT+7'''.";
AutoSlot::usage=\[Bullet]::usage;
AutoSlotSequence::usage=\[Bullet]\[Bullet]::usage;
Private`ProcessingAutoSlot=False;
ToFunction::usage=FormatUsage@"ToFunction[expr] attempts to convert any function constructs inside '''expr''' to pure Functions. Can't convert functions containing SlotSequence. For functions using only indexed Slots, the returned pure function is fully equivalent. If named slots are used, the handling of missing keys/associations is altered.";
Tee::usage=FormatUsage@"Tee[expr] prints expr and returns in afterwards ";
TableToTexForm::usage=FormatUsage@"TableToTexForm[data] returns the LaTeX representation of a list or a dataset ";
FancyTrace::usage=FormatUsage@"FancyTrace[expr] produces an interactive version of the Trace output";
WindowedMap::usage=FormatUsage@"WindowedMap[func,data,width] calls ```func``` with ```width``` wide windows of ```data```, padding with the elements specified by the '''Padding''' option (0 by default, use '''None''' to disable padding and return a smaller array) and returns the resulting list
WindowedMap[func,data,{width_1,\[Ellipsis]}] calls ```func``` with ```width_1```,```\[Ellipsis]``` wide windows of arbitrary dimension
WindowedMap[func,wspec] is the operator form";
KeyGroupBy::usage=FormatUsage@"KeyGroupBy[expr,f] works like '''GroupBy''', but operates on keys
KeyGroupBy[f] is the operator form";
AssociationFoldList::usage=FormatUsage@"AssociationFoldList[f,assoc] works like '''FoldList''', but preserves the association keys";
SPrintF::usage=FormatUsage@"SPrintF[spec,arg_1,\[Ellipsis]] is equivalent to '''ToString@StringForm[```spec```,```arg_1```,\[Ellipsis]]'''";
PrettyUnit::usage=FormatUsage@"PrettyUnit[qty,{unit_1,unit_2,\[Ellipsis]}] tries to convert ```qty``` to that unit that produces the \"nicest\" result";
PrettyTime::usage=FormatUsage@"PrettyTime[time] is a special for of '''PrettyUnit''' for the most common time units";


Begin["Private`"]


MergeRules[rules:(Rule|RuleDelayed)[_,_]..]:=With[
  {ruleList={rules}},
  With[
    {ruleNames=Unique["rule"]&/@ruleList},
    With[
      {
        wRules=Hold@@(List/@ruleNames),
        patterns=ruleList[[All,1]],
        replacements=Extract[ruleList,{All,2},Hold]
      },
      Alternatives@@MapThread[Pattern,{ruleNames,patterns}]:>
        replacements[[1,First@FirstPosition[wRules,{__}]]]
    ]
  ]
]


(*From https://mathematica.stackexchange.com/a/10451/36508*)
SetAttributes[Let,HoldAll];
SyntaxInformation[Let]={"ArgumentsPattern"->{_,_}(*,"LocalVariables"\[Rule]{"Solve",{1}}*)};
Let/:(assign:SetDelayed|RuleDelayed)[lhs_,rhs:HoldPattern[Let[{__},_]]]:=Block[
  {With},
  Attributes[With]={HoldAll};
  assign[lhs,Evaluate[rhs]]
];
Let[{},expr_]:=expr;
Let[{head_},expr_]:=With[{head},expr];
Let[{head_,tail__},expr_]:=Block[{With},Attributes[With]={HoldAll};
With[{head},Evaluate[Let[{tail},expr]]]];


Notation[ParsedBoxWrapper[RowBox[{"expr_", SubscriptBox["//", "="], "wrap_"}]] \[DoubleLongRightArrow] ParsedBoxWrapper[RowBox[{"AssignmentWrapper", "[", RowBox[{"expr_", ",", "wrap_"}], "]"}]]]
AssignmentWrapper/:h_[lhs_,AssignmentWrapper[rhs_,wrap_]]:=If[h===Set||h===SetDelayed,wrap[h[lhs,rhs]],h[lhs,wrap[rhs]]]
Attributes[AssignmentWrapper]={HoldAllComplete};


FunctionError::missingArg="`` in `` cannot be filled from ``.";
FunctionError::noAssoc="`` is expected to have an Association as the first argument.";
FunctionError::missingKey="Named slot `` in `` cannot be filled from ``.";
FunctionError::invalidSlot="`` (in ``) should contain a non-negative integer or string.";
FunctionError::invalidSlotSeq="`` (in ``) should contain a positive integer.";
FunctionError::slotArgCount="`` called with `` arguments; 0 or 1 expected.";

funcData[__]=None;

ProcFunction[(func:fType_[funcExpr_,fData___])[args___]]:=ProcFunction[funcExpr,{args},func,Sequence@@funcData[fType,fData]]
ProcFunction[funcExpr_,args:{argSeq___},func_,{sltPat_:>sltIdx_,sltSeqPat_:>sltSeqIdx_},  levelspec_:\[Infinity],{sltHead_,sltSeqHead_}]:=With[
  {
    hExpr=Hold@funcExpr,
    funcForm=HoldForm@func
  },
  ReleaseHold[
    Replace[
      Replace[
        hExpr,
        {
          s:sltPat:>With[
            {arg=Which[
              Length@{sltIdx}>1,
              Message[FunctionError::slotArgCount,sltHead,Length@{sltIdx}];s,
              StringQ@sltIdx,
              If[
                AssociationQ@First@args,              
                Lookup[First@args,sltIdx,Message[FunctionError::missingKey,sltIdx,func,First@args];s],
                Message[FunctionError::noAssoc,funcForm];s
              ],
              !IntegerQ@sltIdx||sltIdx<0,
              Message[FunctionError::invalidSlot,s,funcForm];s,
              sltIdx==0,
              func,
              sltIdx<=Length@args,
              args[[sltIdx]],
              True,
              Message[FunctionError::missingArg,s,funcForm,
                HoldForm[func@argSeq]];s
            ]},
            arg/;True
          ],
          s:sltSeqPat:>With[
            {arg=Which[
              Length@{sltSeqIdx}>1,            
              Message[FunctionError::slotArgCount,sltSeqHead,Length@{sltSeqIdx}];s,
              !IntegerQ@sltSeqIdx||sltSeqIdx<=0,
              Message[FunctionError::invalidSlotSeq,s,funcForm];s,
              sltIdx<=Length@args+1,
              pfArgSeq@@args[[sltIdx;;]],
              True,
              Message[FunctionError::missingArg,s,funcForm,HoldForm[func@argSeq]];s
            ]},
            arg/;True
          ]
        },
        levelspec
      ]//.
        h_[pre___,pfArgSeq[seq___],post___]:>h[pre,seq,post],
      Hold[]->Hold@Sequence[],
      {0}
    ]
  ]
];
Attributes[ProcFunction]={HoldFirst};


ProcessingAutoSlot=True;
slotMatcher=StringMatchQ["\[Bullet]"~~___];
(
  #/:expr:_[___,#[___],___]/;!ProcessingAutoSlot:=Block[
    {ProcessingAutoSlot=True},
    Replace[auToFunction[expr],{AutoSlot[i___]:>IAutoSlot[i],AutoSlotSequence[i___]:>IAutoSlotSequence[i]},{2}]
  ];
)&/@{AutoSlot,AutoSlotSequence};
MakeBoxes[(IAutoSlot|AutoSlot)[i_String|i:_Integer?NonNegative:1],fmt_]/;!ProcessingAutoSlot:=With[{sym=Symbol["\[Bullet]"<>ToString@i]},MakeBoxes[sym,fmt]]
MakeBoxes[(IAutoSlotSequence|AutoSlotSequence)[i:_Integer?Positive:1],fmt_]/;!ProcessingAutoSlot:=With[{sym=Symbol["\[Bullet]\[Bullet]"<>ToString@i]},MakeBoxes[sym,fmt]]
MakeBoxes[IAutoSlot[i___],fmt_]/;!ProcessingAutoSlot:=MakeBoxes[AutoSlot[i],fmt]
MakeBoxes[IAutoSlotSequence[i___],fmt_]/;!ProcessingAutoSlot:=MakeBoxes[AutoSlotSequence[i],fmt]
MakeBoxes[auToFunction[func_],fmt_]:=MakeBoxes[func,fmt]
MakeExpression[RowBox[{"?", t_String?slotMatcher}], fmt_?(!ProcessingAutoSlot&)(*make check here instead of ordinary condition as that one causes an error*)]:= 
  MakeExpression[RowBox[{"?", If[StringMatchQ[t,"\[Bullet]\[Bullet]"~~___],"AutoSlotSequence","AutoSlot"]}], fmt]
MakeExpression[arg_RowBox?(MemberQ[#,_String?slotMatcher,Infinity]&),fmt_?(!ProcessingAutoSlot&)(*make check here instead of ordinary condition as that one causes an error*)]:=Block[
  {ProcessingAutoSlot=True},
  MakeExpression[
    arg/.a_String:>First[
      StringCases[a,t:("\[Bullet]\[Bullet]"|"\[Bullet]")~~i___:>ToBoxes@If[t=="\[Bullet]",AutoSlot,AutoSlotSequence]@If[StringMatchQ[i,__?DigitQ],ToExpression@i,i/.""->1]],
      a
    ],
    fmt
  ]
]
ProcessingAutoSlot=False;
Attributes[auToFunction]={HoldFirst};
funcData[auToFunction]={{IAutoSlot[i__:1]:>i,IAutoSlotSequence[i__:1]:>i},{2},{AutoSlot,AutoSlotSequence}};
func:auToFunction[_][___]:=ProcFunction[func]
SyntaxInformation[AutoSlot]={"ArgumentsPattern"->{_.}};
SyntaxInformation[AutoSlotSequence]={"ArgumentsPattern"->{_.}};


Notation[ParsedBoxWrapper[SubscriptBox[RowBox[{"func_", "&"}], "id_"]] \[DoubleLongLeftRightArrow]ParsedBoxWrapper[RowBox[{"IndexedFunction", "[", RowBox[{"func_", ",", "id_"}], "]"}]]]
AddInputAlias["cf"->ParsedBoxWrapper[SubscriptBox["&", "\[Placeholder]"]]]
funcData[IndexedFunction,id_]:={{Subscript[Slot[i__:1], id]:>i,Subscript[SlotSequence[i__:1], id]:>i},{Subscript[#, id]&@*Slot,Subscript[#, id]&@*SlotSequence}};
func:IndexedFunction[_,_][___]:=ProcFunction[func]
Attributes[IndexedFunction]={HoldFirst};


ToFunction::slotSeq="Cannot convert function ``, as it contains a SlotSequence (``).";
ToFunction[expr_]:=
expr//.func:fType_[funcExpr_,fData___]:>
  Let[
    {
      hFunc=Hold@funcExpr,
      res=FirstCase[funcData[fType,fData],{{sltPat_:>sltIdx_,sltSeqPat_:>_},  levelspec_:\[Infinity],_}:>With[
        {
          newFunc=If[
            FreeQ[hFunc,sltSeqPat,levelspec],
            Let[
              {
                maxSlt=Max[Max@Cases[hFunc,sltPat:>If[IntegerQ@sltIdx,sltIdx,1],levelspec],0],
                vars=Table[Unique@"fArg",maxSlt],
                pFunc=hFunc/.sltPat:>With[{slot=If[IntegerQ@sltIdx,vars[[sltIdx]],vars[[1]][sltIdx]]},slot/;True]
              },
              Function@@Prepend[pFunc,vars]
            ],
            Message[Unevaluated@ToFunction::slotSeq,HoldForm@func,FirstCase[hFunc,sltSeqPat,"##",levelspec]];$Failed
          ]
        },
        newFunc/;True
      ],
      $Failed,
      {0}
    ]
  },
  res/;res=!=$Failed
]
Attributes[ToFunction]={HoldFirst};


Tee[expr_]:=(Print@expr;expr)
SyntaxInformation[Tee]={"ArgumentsPattern"->{_}};


TableToTexFormCore[TableToTexForm,data_,OptionsPattern[{"position"->"c","hline"->"auto","vline"->"auto"}]]:=Module[
{out,normData,newData,asso1,asso2},
out="";
normData=Normal[data];
asso1=AssociationQ[normData];
asso2=AssociationQ[normData[[1]]];

If[OptionValue["vline"]=="all",
	If[asso1,
		(out=out<>"\\begin{tabular}{ | "<>OptionValue["position"]<>" | ";
		Do[out=out<>OptionValue["position"]<>" | ",Length[normData[[1]]]];),
		(out=out<>"\\begin{tabular}{ | ";
		Do[out=out<>OptionValue["position"]<>" | ",Length[normData[[1]]]];)
	],
	If[asso1,
		(out=out<>"\\begin{tabular}{ | "<>OptionValue["position"]<>" | ";
		Do[out=out<>OptionValue["position"]<>" ",Length[normData[[1]]]];),
		(out=out<>"\\begin{tabular}{ | ";
		Do[out=out<>OptionValue["position"]<>" ",Length[normData[[1]]]];)
	];
	out=out<>"|";
];
out=out<>"}\\hline\n";

If[asso2,
	For[j=1,j<=Length[normData[[1]]],j++,
		If[j==1 ,
			out=If[asso1,
				out<>"& "<>ToString[Keys[normData[[1]]][[1]]],
				out<>ToString[Keys[normData[[1]]][[1]]]],
			out=out<>" & "<>ToString[Keys[normData[[1]]][[j]]]
		];
	];
	out=out<>"\\\\  \\hline \n";
];

For[i=1,i<=Length[normData],i++,
	For[j=If[asso1,0,1,1],j<=Length[normData[[1]]],j++,
		If[j==0,out=out<>ToString[Keys[normData][[i]]],
			If[j==1 &&!asso1,
				out=out<>ToString[normData[[i,1]]],
				out=out<>" & "<>ToString[normData[[i,j]]]
			];
		];
	];
	If[(OptionValue["hline"]=="all"),
		out=out<>" \\\\ \\hline\n",
		out=out<>"\\\\ \n"
	];
];

If[OptionValue["hline"]=="auto",
	out=out<> "\\hline \n"];
	out=out<>"\\end{tabular}"
]


TableToTexForm[args___]:=TableToTexFormCore[TableToTexForm,args];


FancyTraceStyle[i_,o:OptionsPattern[FancyTrace]]:=Style[i,o,FontFamily->"Consolas",Bold]
FancyTraceShort[i_,fac_,o:OptionsPattern[FancyTrace]]:=Tooltip[Short[i,fac OptionValue["ShortWidth"]],Panel@FancyTraceStyle[i,o],TooltipStyle->{CellFrame->None,Background->White}]
FancyTraceArrowStyle[a_,o:OptionsPattern[FancyTrace]]:=Style[a,OptionValue["ArrowColor"],FontSize->OptionValue["ArrowScale"]OptionValue[FontSize]]
FancyTracePanel[i_,o:OptionsPattern[FancyTrace]]:=Panel[i,Background->OptionValue["PanelBackground"],ContentPadding->False]
FancyTraceColumn[l_,o:OptionsPattern[FancyTrace]]:=Column[
 Riffle[
  IFancyTrace[#,"PanelBackground"->Darker[OptionValue["PanelBackground"],OptionValue["DarkeningFactor"]],o]&/@l,
  If[OptionValue["DownArrows"],FancyTraceArrowStyle["\[DoubleDownArrow]",o],Nothing]
 ],
 Alignment->OptionValue["ColumnAlignment"]
]
Options[FancyTrace]=Options[Style]~Join~{"ArrowColor"->Darker@Red,"ArrowScale"->1.5,"ShortWidth"->0.15,"TraceFilter"->Sequence[],"TraceOptions"->{},"DarkeningFactor"->0.1,"PanelBackground"->White,"DownArrows"->False,"ColumnAlignment"->Left};
FancyTrace[expr_,o:OptionsPattern[]]:=Framed@IFancyTrace[Trace[expr,Evaluate@OptionValue["TraceFilter"],Evaluate[Sequence@@OptionValue["TraceOptions"]]]/.s:(Slot|SlotSequence):>Defer[s],o]
SetAttributes[FancyTrace,HoldFirst]
IFancyTrace[l_List,o:OptionsPattern[FancyTrace]]:=
DynamicModule[
 {expanded=False},
  EventHandler[
   FancyTracePanel[
    Dynamic@If[
     expanded,
     FancyTraceColumn[l,o],
     FancyTraceStyle[Row@{
      FancyTraceShort[First@l,1,o],
      If[
        Length@l<3,
        FancyTraceArrowStyle[" \[DoubleRightArrow] ",o],
        Tooltip[FancyTraceArrowStyle[" \[DoubleRightArrow] \[CenterEllipsis] \[DoubleRightArrow] ",o],FancyTraceColumn[l[[2;;-2]],o],TooltipStyle->{CellFrame->None,Background->OptionValue["PanelBackground"]}]
       ],
      FancyTraceShort[Last@l,1,o]
     },
     o
    ]
   ],
   o
  ],
  {"MouseClicked":>(expanded=!expanded)},
  PassEventsUp->False
 ]
]
IFancyTrace[i_,o:OptionsPattern[FancyTrace]]:=FancyTracePanel[FancyTraceStyle[FancyTraceShort[i,2,o],o],o]
IFancyTrace[{},o:OptionsPattern[FancyTrace]]:=Panel[Background->OptionValue["PanelBackground"]]


WindowedMap[f_,d_,w_Integer,o:OptionsPattern[]]:=WindowedMap[f,d,{w},o]
WindowedMap[f_,w_Integer,o:OptionsPattern[]][d_]:=WindowedMap[f,d,w,o]
WindowedMap[f_,d_,w:{__Integer}|_Integer,OptionsPattern[]]:=
With[
  {ws=If[Head@w===List,w,{w}]},
    Map[
      f,
      Partition[
      If[
        OptionValue@Padding===None,
        d,
        ArrayPad[d,Transpose@Floor@{ws/2,(ws-1)/2},Nest[List,OptionValue@Padding,Length@ws]]
      ],
      ws,
      Table[1,Length@ws]
    ],
    {Length@ws}
  ]
]
WindowedMap[f_,w:{__Integer}|_Integer,o:OptionsPattern[]][d_]:=WindowedMap[f,d,w,o]
Options[WindowedMap]={Padding->0};
SyntaxInformation[WindowedMap]={"ArgumentsPattern"->{_,_,_.,OptionsPattern[]}};


KeyGroupBy[f_][expr_]:=Association/@GroupBy[Normal@expr,f@*Keys]
KeyGroupBy[expr_,f_]:=KeyGroupBy[f][expr]
SyntaxInformation[KeyGroupBy]={"ArgumentsPattern"->{_,_.}};


AssociationFoldList[f_,list_]:=AssociationThread[Keys@list,FoldList[f,Values@list]]
SyntaxInformation[AssociationFoldList]={"ArgumentsPattern"->{_,_}};


SPrintF[spec__]:=ToString@StringForm@spec


PrettyUnit[qty_,units_List]:=SelectFirst[#,QuantityMagnitude@#>1&,Last@#]&@Sort[UnitConvert[qty,#]&/@units]
SyntaxInformation[PrettyUnit]={"ArgumentsPattern"->{_,_}};


$PrettyTimeUnits={"ms","s","min","h"};
PrettyTime[time_]:=PrettyUnit[time,$PrettyTimeUnits]
SyntaxInformation[PrettyTime]={"ArgumentsPattern"->{_}};


End[]


EndPackage[]


(* --- Styling Part --- *)


BeginPackage["ForScience`PlotUtils`"]


Jet::usage="magic colors from http://stackoverflow.com/questions/5753508/custom-colorfunction-colordata-in-arrayplot-and-similar-functions/9321152#9321152"


Begin["Private`"]


Jet[u_?NumericQ]:=Blend[{{0,RGBColor[0,0,9/16]},{1/9,Blue},{23/63,Cyan},{13/21,Yellow},{47/63,Orange},{55/63,Red},{1,RGBColor[1/2,0,0]}},u]/;0<=u<=1


ThemeFontStyle=Directive[Black,FontSize->20,FontFamily->"Times"];


SmallThemeFontStyle=Directive[Black,FontSize->18,FontFamily->"Times"];


NiceRadialTicks/:Switch[NiceRadialTicks,a___]:=Switch[Automatic,a]/.l:{__Text}:>Most@l
NiceRadialTicks/:MemberQ[a___,NiceRadialTicks]:=MemberQ[a,Automatic]


BasicPlots={ListContourPlot};
PolarPlots={ListPolarPlot};
PolarPlotsNoJoin={PolarPlot};
ThemedPlots={LogLogPlot,ListLogLogPlot,ListLogPlot,ListLinePlot,ListPlot,Plot,ParametricPlot,SmoothHistogram};
Plots3D={ListPlot3D,ListPointPlot3D,ParametricPlot3D};
HistogramType={Histogram,BarChart,PieChart};


Themes`AddThemeRules["ForScience",Plots3D,
	  LabelStyle->ThemeFontStyle,PlotRangePadding->0
]


Themes`AddThemeRules["ForScience",ThemedPlots,
	  LabelStyle->ThemeFontStyle,PlotRangePadding->0,
	  PlotTheme->"VibrantColors"
	  LabelStyle->ThemeFontStyle,
	  FrameStyle->ThemeFontStyle,
	  FrameTicksStyle->SmallThemeFontStyle,
	  Frame->True,
	  PlotRangePadding->0,
	  Axes->False
]


Themes`AddThemeRules["ForScience",BasicPlots,
	  LabelStyle->ThemeFontStyle,PlotRangePadding->0,
	  PlotTheme->"VibrantColors",
	  LabelStyle->ThemeFontStyle,
	  FrameStyle->ThemeFontStyle,
	  FrameTicksStyle->SmallThemeFontStyle,
	  Frame->True,
	  PlotRangePadding->0,
	  Axes->False
]


Themes`AddThemeRules["ForScience",PolarPlots,
	  Joined->True,
	  Mesh->All,
	  PolarGridLines->Automatic,
	  PolarTicks->{"Degrees",NiceRadialTicks},
	  TicksStyle->SmallThemeFontStyle,
	  Frame->False,
	  PolarAxes->True,
	  PlotRangePadding->Scaled[0.1]
]


Themes`AddThemeRules["ForScience",PolarPlotsNoJoin,
	  Mesh->All,
	  PolarGridLines->Automatic,
	  PolarTicks->{"Degrees",NiceRadialTicks},
	  TicksStyle->SmallThemeFontStyle,
	  Frame->False,
	  PolarAxes->True,
	  PlotRangePadding->Scaled[0.1]
]


Themes`AddThemeRules["ForScience",HistogramType,
	  ChartStyle -> {Pink} (* Placeholder *)
]


End[]


EndPackage[]
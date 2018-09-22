(* ::Package:: *)

ProgressReport::usage=FormatUsage@"ProgressReport[expr,len] displays a progress report while ```expr``` is being evaluated, where ```len``` is the number of steps. To indicate that a step is finished, call '''Step'''. If '''SetCurrent''' is used, the currently processed item is also displayed.
ProgressReport[expr] automatically injects '''Step''' and '''SetCurrent''' for certain types of ```expr```. Currently supported types of expressions can be found in '''ProgressReportTransform'''.";
ProgressReportTransform::usage=FormatUsage@"'''ProgressReportTransform''' handles automatic transformations in '''ProgressReport[```expr```]'''. New transformations can be added as down-values.";
ProgressReportingFunction::usage=FormatUsage@"ProgressReportingFunction is the head of the operator form of a expression transformed by ProgressReportTransform.";
Step::usage=FormatUsage@"'''Step''' is used inside '''ProgressReport''' to indicate a step has been finished. '''Step''' passes through any argument passed to it. A typical use would be e.g. '''Step@*proc''' where '''proc''' is the function doing the actual work.";
SetCurrent::usage=FormatUsage@"SetCurrent[curVal] sets the currently processed item (displayed by '''ProgressReport''') to the specified value.";
SetCurrentBy::usage=FormatUsage@"SetCurrentBy[curFunc] sets the currently processed item (displayed by '''ProgressReport''') by applying ```curFunc``` to its argument (the argument is also returned). A typical use would be e.g. '''Step@*proc@*SetCurrentBy[```curFunc```]'''.
SetCurrentBy[] defaults ```curFunc``` to the identity function.";


Begin["`Private`"]


PRPrettyTime[s_]:=
Which[
  s>86400,
  SPrintF["``days",Round[s/86400,0.1]],
  s>3600,
  SPrintF["``h",Round[s/3600,0.1]],
  s>60,
  SPrintF["``min",Round[s/60,0.1]],
  s>1,
  SPrintF["``s",Round[s,0.1]],
  True,
  SPrintF["``ms",Round[1000s,0.1]]
]


Attributes[ProgressReport]={HoldFirst};


SyntaxInformation[ProgressReport]={"ArgumentsPattern"->{_,_.,OptionsPattern[]}};


Options[ProgressReport]={"Resolution"->Automatic,Timing->True,"Parallel"->False};


ProgressReport::injectFailed="Could not automatically inject tracking functions into ``. See ProgressReportTransform for supported types.";


ProgressReport[expr_,len:(_Integer|Indeterminate),o:OptionsPattern[]]:=
If[OptionValue[Timing],
  iTimedProgressReport[expr,len,FilterRules[{o,Options[ProgressReport]},_]],
  iProgressReport[expr,len,FilterRules[{o,Options[ProgressReport]},_]]
]
ProgressReport[expr_,0,OptionsPattern[]]:=expr
ProgressReport[expr_,o:OptionsPattern[]]:=ProgressReportTransform[expr,o]


Attributes[iTimedProgressReport]={HoldFirst};


Options[iTimedProgressReport]=Options[ProgressReport];


iTimedProgressReport[expr_,len_,OptionsPattern[]]:=Module[
  {
    i,
    start,
    pExpr,
    cur,
    time,
    times=<||>,
    durations=<|0->0|>,
    totals=<||>,
    prevProg=0,
    knownLen=len=!=Indeterminate,
    progTemp,
    res
  },
  res=OptionValue["Resolution"]/.
   Automatic:>If[knownLen,Scaled[1/20],5]/.
    {Scaled[r_]:>1/r*If[knownLen,1/len,1],r_:>1/r};
  pExpr=HoldComplete[expr]/.
  {
    SetCurrent:>ISetCurrent[cur],
    SetCurrentBy[curFunc_:(#&)]:>ISetCurrentBy[cur,curFunc],
    Step->IStep[i,res,time,times]
  };
  If[OptionValue["Parallel"],SetSharedVariable[i,times,time,cur]];
  i=0;
  cur=None;
  progTemp=StringTemplate[If[knownLen,"``/``","``"]];
  Return@Monitor[
    time=start=AbsoluteTime[];
    ReleaseHold@pExpr,
    Panel@Row@{
      Dynamic[
        With[
          {
            dur=time-start,
            pdur=Last[times,0]-start,
            prog=Last[Keys@times,0]
          },
          If[prog>prevProg,
            AppendTo[durations,prog->pdur];
            AppendTo[totals,prog->If[knownLen,len/prog,1]*durations[[-1]]];
            If[prevProg==0,PrependTo[totals,0->If[knownLen,totals[[1]],0]]];
            prevProg=prog;
          ];
          Grid[
            {
              If[cur=!=None,{"Current item:",Tooltip[FixedShort[cur,20],cur]},Nothing],
              {"Progess:",progTemp[i,len]},
              {"Time elapsed:",If[i==0,"NA",PRPrettyTime@dur]},
              {"Time per Step:",If[i==0,"NA",PRPrettyTime[dur/i]]},
              If[knownLen,{"Est. time remaining:",If[i==0,"NA",PRPrettyTime[(len-i)*dur/i]]},Nothing],
              If[knownLen,{"Est. total time:",If[i==0,"NA",PRPrettyTime[len*dur/i]]},Nothing]
            },
            Alignment->{{Left,Right}},
            ItemSize->{{10,13},{1.5,1.5,1.5,1.5,1.5,1.5}}
          ]
        ],
        TrackedSymbols:>{i,cur}
      ],
      Spacer@10,
      Dynamic[
        With[
          {max=Max[totals,0]},
          With[
            {
              tPts=List@@@Normal@totals,
              dPts=List@@@Normal@durations
            },
            Graphics[
              {
                Darker@Green,
                Opacity@0.3,
                Rectangle[{0,0},{prevProg,max}],
                Opacity@0.5,
                Polygon[Join[tPts,{{prevProg,0},{0,0}}]],
                Opacity@1,
                Polygon[Join[dPts,{{prevProg,0},{0,0}}]],
                White,
                AbsoluteThickness@1.6,
                Line@dPts,
                Dashed,
                Line@tPts
              },
              FrameTicks->None,
              Frame->False,
              Axes->None,
              PlotRangePadding->0,
              ImageSize->300,
              PlotRange->{{0,If[knownLen,len,prevProg+1/res]},{0,max}},
              GridLines->If[knownLen,{len*{0.2,0.4,0.6,0.8},Automatic},Automatic],
              GridLinesStyle->Directive[White,Opacity@0.75],
              Method->{"GridLinesInFront"->True},
              Background->GrayLevel@0.9,
              AspectRatio->1/GoldenRatio
            ]
          ]
        ]
      ]
    }
  ]
]


Attributes[iProgressReport]={HoldFirst};


Options[iProgressReport]=Options[ProgressReport];


iProgressReport[expr_,len_,OptionsPattern[]]:=Module[
  {
    i,
    pExpr,
    cur,
    knownLen=len=!=Indeterminate,
    progTemp
  },
  pExpr=HoldComplete[expr]/.
  {
    SetCurrent:>ISetCurrent[cur],
    SetCurrentBy[curFunc_:(#&)]:>ISetCurrentBy[cur,curFunc],
    Step->IStep[i]
  };
  If[OptionValue["Parallel"],SetSharedVariable[i,cur]];
  i=0;
  cur=None;
  progTemp=StringTemplate[If[knownLen,"``/``","``"]];
  Return@Monitor[
    ReleaseHold@pExpr,
    Dynamic[
      Panel@Row@{
        Grid[
          {
            If[cur=!=None,{"Current item:",Tooltip[FixedShort[cur,20],cur]},Nothing],
            {"Progess:",progTemp[i,len]}
          },
          Alignment->{{Left,Right}},
          ItemSize->{{10,13},{1.5,1.5}}
        ],
        Spacer@10,
        If[knownLen,
          ProgressIndicator[i,{0,len},ImageSize->300],
          ProgressIndicator[i/5,Indeterminate,ImageSize->300]
        ]
      },
      TrackedSymbols:>{i,cur}
    ]
  ]
]


Attributes[IStep]={HoldAll};


IStep[i_,res_,time_,times_][expr___]:=(
  time=AbsoluteTime[];
  If[Floor[res i]<Floor[res (++i)],
    AppendTo[times,i->time]
  ];
  Unevaluated@expr
)


IStep[i_][expr___]:=(++i;Unevaluated@expr)


SyntaxInformation[Step]={"ArgumentsPattern"->{_.}};


Attributes[ISetCurrent]={HoldFirst};


ISetCurrent[cur_Symbol][curVal_]:=(cur=curVal)


SyntaxInformation[SetCurrent]={"ArgumentsPattern"->{_}};


Attributes[ISetCurrentBy]={HoldFirst};


ISetCurrentBy[cur_Symbol,curFunc_][expr___]:=(cur=curFunc@expr;Unevaluated@expr)


SyntaxInformation[SetCurrentBy]={"ArgumentsPattern"->{_.}};


DistributeDefinitions[IStep,ISetCurrent,ISetCurrentBy];


InjectTracking[func_]:=Function[
  Null,
  SetCurrent[HoldForm@#];
  With[
    {ret=func@##},
    Step[];
    ret
  ],
  {HoldAll}
]


InjectTracking[func_,All]:=Function[
  Null,
  SetCurrent[HoldForm@{##}];
  With[
    {ret=func@##},
    Step[];
    ret
  ],
  {HoldAll}
]


Attributes[HandleParallelize]={HoldFirst};


HandleParallelize[expr_,n_,o:OptionsPattern[ProgressReportTransform]]:=
With[
  {
    pOpts=OptionValue@Parallelize,
    opts=FilterRules[{o},Options@ProgressReport]
  },
  If[pOpts===False,
    ProgressReport[expr,n,opts],
    ProgressReport[Parallelize[expr,pOpts],n,"Parallel"->True,opts]
  ]
]


Attributes[ProgressReportTransform]={HoldFirst};


Options[ProgressReportTransform]=Options[ProgressReport]~Join~{Parallelize->False};


ProgressReportTransform[Parallelize[expr_,po:OptionsPattern[]],o:OptionsPattern[]]:=
ProgressReportTransform[expr,Parallelize->{po},o]


ProgressReportTransform[
  ParallelMap[f_,list_,level_|PatternSequence[],Longest[po:OptionsPattern[]]],
  o:OptionsPattern[]
]:=
ProgressReportTransform[Map[f,list,level],Parallelize->{po,Options@ParallelMap},o]


ProgressReportTransform[
  Map[Map[func_],list_,level:RepeatedNull[{_Integer},1]]|
   HoldPattern[Map[Map[func_],#,level:RepeatedNull[{_Integer},1]]&[list_]]|
   Map[Map[func_]][list_],
  o:OptionsPattern[]
]:=
With[
  {newLevel=1+DefTo[level,{1}]},
  ProgressReportTransform[Map[func,list,newLevel],o]
]
ProgressReportTransform[
  (m:Map|AssociationMap|MapIndexed)[func_,list_,level:RepeatedNull[_,1]]|
   HoldPattern[(m:Map|AssociationMap|MapIndexed)[func_,#,level:RepeatedNull[_,1]]&[list_]]|
   (m:Map|AssociationMap|MapIndexed)[func_][list_],
  o:OptionsPattern[]
]/;m=!=AssociationMap||Length@{level}===0:=
With[
  {elist=list},
  ProgressReportTransform[
    m[func,elist,level],
    Evaluated,
    o
  ]
]
ProgressReportTransform[
  op:(m:Map|AssociationMap|MapIndexed)[_]|
   ((m:Map|AssociationMap|MapIndexed)[_,#,level:RepeatedNull[_,1]]&)|
   (m:MapAt)[_,_],
  o:OptionsPattern[]
]/;m=!=AssociationMap||Length@{level}===0:=
ProgressReportingFunction[m,op,o]
ProgressReportTransform[
  (m:Map|(am:AssociationMap)|MapIndexed)[func_,list_,level_:{1}],
  Evaluated,
  o:OptionsPattern[]
]:=
With[
  {
    pFunc=InjectTracking@func,
    pLevel=InvCondDef[am][level]
  },
  HandleParallelize[
    m[
      pFunc,
      list,
      pLevel
    ],
    Length@Level[list,level,Hold],
    o
  ]
]
ProgressReportTransform[
  (m:Map|MapIndexed)[func_,ass_Association,{1}],
  Evaluated,
  o:OptionsPattern[]
]:=
HandleParallelize[
  MapIndexed[
    Function[
      Null,
      SetCurrent[Extract[#2,{1,1},HoldForm]];
      With[
        {ret=If[m===MapIndexed,func@##,func@#]},
        Step[];
        ret
      ],
      {HoldAll}
    ]&,
    ass
  ],
  Length@ass,
  o
]


ProgressReportTransform[
  MapAt[func_,list_,pos_]|MapAt[func_,pos_][list_],
  o:OptionsPattern[]
]:=
With[
  {pFunc=InjectTracking@func},
  HandleParallelize[
    MapAt[
      pFunc,
      list,
      pos
    ],
    Count[
      MapAt[
        MapAtCounter,
        Hold@@list,
        pos
      ],
      MapAtCounter,
      All,
      Heads->True
    ],
    o
  ]
]


ProgressReportTransform[q:Query[__],o:OptionsPattern[]]:=
With[
  {
    op=Check[
      ProgressReportTransform[Evaluate@Normal@q,o],
      $Failed,
      {ProgressReport::injectFailed}
    ]
  },
  (
    op/.ProgressReportingFunction[_,args__]:>
     ProgressReportingFunction[Query,args]
  )/;op=!=$Failed
]
ProgressReportTransform[(q:Query[__])[expr_],o:OptionsPattern[]]:=
With[
  {nq=Normal@q},
  ProgressReportTransform[nq[expr],o]
]


Attributes[VarSpec]={HoldFirst};


Attributes[NumericSpecQ]={HoldFirst};


NumericSpecQ[expr_]:=NumericQ@Unevaluated@expr


Attributes[NumericIteratorSpecQ]={HoldFirst};


NumericIteratorSpecQ[expr_]:=MatchQ[
  Unevaluated@expr,
  _?NumericSpecQ|
   {_?NumericSpecQ}|
   {_,Repeated[_?NumericSpecQ,{1,2}]}|
   {_,{___?NumericSpecQ}}
]


ProgressReportTransform[ParallelTable[expr_,spec___,Longest[po:OptionsPattern[]]],o:OptionsPattern[]]:=
ProgressReportTransform[Table[expr,spec],Parallelize->{po,Options@ParallelTable},o]


ProgressReportTransform[
  Table[expr_,spec___],
  o:OptionsPattern[]
]:=
Module[
  {
    hSpec=Hold[spec],
    normArgs,
    trackedSpec,
    symbols
  },
  normArgs=Max[
    LengthWhile[hSpec,NumericIteratorSpecQ],
    1
  ];
  trackedSpec=Replace[
    hSpec[[;;normArgs]],
    (n:Except[_List])|{n_}:>With[
      {s={Unique@"ProgressVariable",n}},
      s/;True
    ],
    {1}
  ];
  trackedSpec=List@@@Evaluate/@VarSpec@@@trackedSpec;
  symbols=trackedSpec[[All,1]];
  HandleParallelize[
    {trackedSpec,hSpec[[normArgs+1;;]]}/.
     {Hold[tr__],Hold[rem___]}:>Table[SetCurrent@@symbols;Step@Table[expr,rem],tr],
    Times@@(
      trackedSpec/.
       {
         {_,l_List}:>Length@l,
         {_,s__}:>Length@Range@s
       }
    ),
    o
  ]
]


ProgressReportTransform[ParallelArray[expr_,spec___,Longest[po:OptionsPattern[]]],o:OptionsPattern[]]:=
ProgressReportTransform[Array[expr,spec],Parallelize->{po,Options@ParallelArray},o]


ProgressReportTransform[
  Array[func_,nSpec_,rSpec_|PatternSequence[],h_|PatternSequence[]],
  o:OptionsPattern[]
]:=
With[
  {
    pFunc=InjectTracking[func,All],
    pNSpec=nSpec
  },
  HandleParallelize[
    Array[
      pFunc,
      pNSpec,
      rSpec,
      h
    ],
    Times@@pNSpec,
    o
  ]
]


ProgressReportTransform[
  (nest:Nest|NestList)[func_,expr_,n_],
  o:OptionsPattern[]
]:=
With[
  {
    pFunc=InjectTracking@func,
    pN=#&@n
  },
  HandleParallelize[
    nest[
      pFunc,
      expr,
      pN
    ],
    pN,
    o
  ]
]


ProgressReportTransform[
  (fold:Fold|FoldList)[func_,x_|PatternSequence[],expr_]|
   fp:(fold:FoldPair|FoldPairList)[func_,x_|PatternSequence[],expr_,g_|PatternSequence[]]|
   (fold:Fold|FoldList)[func_][expr_],
  o:OptionsPattern[]
]:=
Let[
  {
    eFunc=func
    pFunc=InjectTracking@eFunc,
    pExpr=expr,
    n=Length@Hold[x]+Length[pExpr]-1
  },
  If[
    TrueQ[n>Length@{fp}], (* check if expression will evaluate: either n>0 or (n>-1 and not FoldPair* ) *)
    HandleParallelize[
      fold[
        pFunc,
        x,
        pExpr,
        g
      ],
      n,
      o
    ],
    If[OptionValue@Parallelize=!=False,Parallelize,#&]@fold[
      eFunc,
      x,
      pExpr,
      g
    ]
  ]
]
ProgressReportTransform[op:(fold:Fold|FoldList)[_],o:OptionsPattern[]]:=
ProgressReportingFunction[fold,op,o]


ProgressReportTransform[expr_,OptionsPattern[]]:=(Message[ProgressReport::injectFailed,HoldForm@expr];expr)


ProgressReportingFunction[_,op_,o:OptionsPattern[]][expr_]:=ProgressReportTransform[op[expr],o]


MakeBoxes[f:ProgressReportingFunction[type_,__],frm_]^:=BoxForm`ArrangeSummaryBox[
  ProgressReportingFunction,
  f,
  ProgressIndicator[0.5,ImageSize->{20,20/GoldenRatio}],
  {BoxForm`SummaryItem@{"Operator type: ",type}},
  {},
  frm
]


End[]

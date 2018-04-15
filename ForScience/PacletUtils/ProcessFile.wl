(* ::Package:: *)

ProcessFile::usage=FormatUsage@"ProcessFile[file,{proc_1,\[Ellipsis]}] loads ```file```, applies all functions ```proc_i``` in order to the list of held expressions, and exports the result to the same file again.
ProcessFile[{in,out},{proc_1,\[Ellipsis]}] loads file ```in``` and writes the result to ```out```.
ProcessFile[{proc_1,\[Ellipsis]}] is the operator form.";


Begin["`Private`"]


SyntaxInformation[ProcessFile]={"ArgumentsPattern"->{_.,{__}}};


ProcessFile::msgs="Messages were generated during processing of '``'.";

ProcessFile[_,{}]:=Null
ProcessFile[processors_][file_]:=ProcessFile[file,processors]
ProcessFile[file_,processors_List]:=ProcessFile[{file,file},processors]
ProcessFile[{in_,out_},processors_List]:=Block[
  (*set context to ensure proper context prefixes for symbols.
    Adapted from https://mathematica.stackexchange.com/a/124670/36508*)
  {$Context="ProcessFile`",$ContextPath={"ProcessFile`","System`"}},
  Quiet[
    Check[
      Export[
        out,
        (RightComposition@@processors)[
          Import[in,{"Package","HeldExpressions"}]
        ],
        {"Package","HeldExpressions"},
        PageWidth->Infinity
      ],
      Message[ProcessFile::msgs,in]
    ];
    {General::shdw}
  ];
  Quiet@Remove["ProcessFile`*"];
]


End[]
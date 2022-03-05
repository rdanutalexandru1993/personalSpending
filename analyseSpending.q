//#########################################################################################
//
//  Author : AR 
//  Year   : 2022
//
//  Execution: q analyseSpending.q -p 5000 -printToScreen // print analysis to screen 
//             q analyseSpending.q -p 5000 -printToFile   // print analysis to file
//#########################################################################################
cmdline:.Q.opt .z.x; 

// the base currency used to convert from currency to 
// for example if currency is RON then we use the 
// .config.currency to know which exchange rate to get
.config.currency:`GBP;  

.util.castingStrings:(!) . flip((`regular_spending ; "ISSFIDD");
                                (`spending          ; "SFFSSD*S*F")); 

.util.monthMapping:(!) . flip((1i  ; `January   ); 
                              (2i  ; `February  ); 
                              (3i  ; `March     ); 
                              (4i  ; `April     ); 
                              (5i  ; `May       ); 
                              (6i  ; `June      ); 
                              (7i  ; `July      ); 
                              (8i  ; `August    ); 
                              (9i  ; `September ); 
                              (10i ; `October   ); 
                              (11i ; `November  ); 
                              (12i ; `December  ));

.util.setEnvironment:{
  // set .util.print 
  $[`printToFile in key cmdline;
      [
        // create file name 
        fileName:"spending_report_",(ssr[;".";"_"]string .z.d),".txt";
        path:"/"sv(first system"pwd";fileName); 
        // create file
        -1"Creating file : ",path;
        system"touch ",path; 
        -1"Opening handle to file ..."; 
        `.util.handleToFile set hopen hsym`$path; 
        `.util.print set {[x] neg[.util.handleToFile] x}; 
        ]; 
      `.util.print set {[x] -1 x }
      ]; 
  };

.util.loadData:{
  toLoad:system"ls | grep csv";
  
  if[any toDrop:not(`$first each"."vs/:toLoad)in key .util.castingStrings;
      -1"[WARN] Dropping the following csvs because they're specified in .util.castingStrings:","|"sv toLoad where toDrop;
      toLoad:toLoad where not toDrop];

  {
    -1"[INFO] Loading ",x,"... "; 
    
    fileName:`$first"."vs x;
    suffix:`$last"."vs x;  
    
    .Q.dd[`.data;fileName]set(.util.castingStrings fileName;$[suffix like"csv";enlist",";enlist"|"])0:hsym`$x; 
    }each toLoad; 
  }; 

.util.getExchangeRates:{
  `.data.exchangeRates set{update exchangeRate:{[crncy;dt]$[crncy in`RON;6;crncy in`HUF;427;crncy in`EUR;1.2;crncy in`RSD;140.8;crncy in`USD;1.37;1]}'[currency;date]from delete cnts from 0!x}select cnts:count i by date,currency from .data.spending where not null currency; 
  }; 

.util.updateExchangeRates:{
  tab:value x; 
  tab:tab lj`date`currency xkey .data.exchangeRates;
  tab:update amntInBaseC:{[amnt;eRate]0f^amnt%eRate}'[amount;exchangeRate]from tab;  
  x set tab
  }; 

.util.prepData:{
  res:update currency:`GBP from .data.spending where null currency;
  res:update timestamp:{[dt;t]$[t like"";0Np;dt+"T"$t]}'[date;time]from res;
  
  `.data.spending set res 
  }; 

.analyse.getMaxDate:{
  // function to get max date in the report. 
  exec max date from x
  }; 

.analyse.getMinDate:{
  // function to get min date in the report. 
  exec min date from x
  }; 

.analyse.getAggSpendingByCat:{[sd;ed]
  select sum amount,sum amntInBaseC 
  by category,subcategory 
  from .data.spending 
  where date within(sd;ed)
  };

.analyse.getSpendByCat7Days:{
  sd:neg[7]+ed:.analyse.getMaxDate .data.spending; 
  .analyse.getAggSpendingByCat[sd;ed]
  }

.analyse.getSpendByCat30Days:{
  sd:neg[30]+ed:.analyse.getMaxDate .data.spending; 
  .analyse.getAggSpendingByCat[sd;ed]
  } 

.analyse.compareSpendingByCatPast6Months:{
  fromMonth:neg[6]+toMonth:`month$.z.p; 
  
  res:select from .data.spending where(`month$date)within(fromMonth;toMonth); 
  res:update year:`year$date,month:`mm$date from res;
  res:update monthName:.util.monthMapping month from res;
  res:update yearMonth:`${[x;y]"_"sv(x;y)}'[string year;string monthName]from res; 

  monthOrder:update ind:i from`year`month xasc select ind:count i by year,month,yearMonth from res; 
  
  res:select sum amntInBaseC by category,subcategory,yearMonth from res; 
  res:select category:`${[x;y]"_"sv(x;y)}'[string category;string subcategory],
             yearMonth,
             amntInBaseC
      from res; 
  P:exec asc distinct yearMonth from res; 
  res:exec P#(yearMonth!amntInBaseC)by category:category from res; 
  `category xasc`category xkey(`category,exec yearMonth from monthOrder)xcols 0!res
  }; 

.analyse.printReport:{
  .util.print "";
  .util.print "----------------------------------------------------------------------------------------";
  .util.print " - Period in report : ",string[.analyse.getMinDate .data.spending]," - ",string[.analyse.getMaxDate .data.spending]; 
  .util.print "";
  .util.print " - Spending past 7 days by category : ";
  .util.print "";
  .util.print .Q.s .analyse.getSpendByCat7Days[];
  .util.print ""; 
  .util.print " - Spending past 30 days by category : ";
  .util.print ""; 
  .util.print .Q.s .analyse.getSpendByCat30Days[]; 
  .util.print "";
  .util.print " - Spending by category,month for past 6 month";
  .util.print .Q.s .analyse.compareSpendingByCatPast6Months[];
  .util.print "";
  .util.print "----------------------------------------------------------------------------------------";
  };

main:{
  system"c 20000 20000"; 
  .util.loadData[];
  
  .util.setEnvironment[]; 
  
  .util.prepData[]; 
  
  .util.getExchangeRates[]; 
  
  .util.updateExchangeRates`.data.spending; 
  
  .analyse.printReport[]; 
  };

$[not system"e";@[main;`;{-2"Failed to run main with error : ",x}];main[]] 
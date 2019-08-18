% Program:  LTCM Delta Hedging
% Group:    Team Ganda
% Authors:
%           Yazeed Amr - 260614843 
%           Tawfiq Najjar - 260602165 
%           Sammy Jondi - 260609791
%           
% Last Modified: 2017-11
%
% Course: Applied Quantitative Finance
%
% Project: LTCM Delta Hedging Assingment
%
% Purpose of the program: To track the profit and loss of both sides of a
% call option transaction over a set time defined by the user of the code, 
% with the seller of the call option delta hedging its position. The main
% purpose is at the discretion of the user, however, we used it in order to
% track these values throughout 1998 from January 5th onwards for a 5-year
% dated call option, while also tracking any associated Black Scholes
% values in order to track any anomalies to certain factors.
%
% Files Used: vix.csv
%--------------------------------------------------------------------------           
% Inputs: basis, nmbr, T, mrkp, X
%
% 1) basis: Variable utilized in the 'yearfrac' function. Can take on any
% values indicated in the doc of the 'yearfrac' function. Used in order to
% alter the money market conventions used in calculating the amount of 
% years between any two trading days. Can be altered in order to comply
% with different policies.
%
% 2) nmbr: Number of call options to be underwritten.
%
% 3) T: Call option maturity date.
%
% 4) mrkp: Markup applied on volatility of call option on the first day.
%
% 5) X: strike price of call option
%--------------------------------------------------------------------------
% Dataset descriptions: The table, 'vix.csv', contains the following:
%         
% 1) Date: Contains dates.

% 2) vix: Contains the value of the VIX index at different dates.

% 3) sp500: Contains the value of the S&P500 Index at different dates.

% 4) sigma: Implied volatility of the S&P500 Index at different dates.
% Calculated by dividing the value fo the VIX Index by 100.

% 5) r: Contains interest rates at different dates.
%--------------------------------------------------------------------------
% Outputs: ltcm table, which includes the following outputs:
% 
% 1) timeToMat: Calculates the time to maturity for every trading day.
%
% 2) delta: Calculates the Black Scholes Delta for every trading day.

% 3) gamma: Calculates the Black Scholes Gamma for every trading day.
%
% 4) vega: Calculates the Black Scholes Vega for every trading day.
%
% 5) moneyness: Calculates the Moneyness for every trading day.
%
% 6) callPrice: Calculates the market value of the call option for every 
% trading day.
%
% 7) clientCallPrice: Similar to the callPrice column, except the first
% entry is different due to the markup applied on the first day.
%
% 8) cash: Cash account.
%
% 9) hedgePL: Profit and Loss for the hedged position.
%
% 10) clientPL: Profit and Loss for the client.
%
% 11) netPortfolioValue: Net Portfolio Value.
%
% The following 6 plots are also outputted by the code: 
%   - Client P&L, Hedge P&L, cash account evolution over time
%   - Delta and S&P500 over time
%   - Gamma and moneyness over time
%   - Vega VIX over time
%   - Net Portfolio Value and Interest Rate over Time
%   - S&P500 and Hedge P&L over Time

%% 1 - Load data file
vix=readtable('vix.csv');

%% 2 - Create ltcm table
% Define variable for only year 1997, from 2nd Jan onwards, for extraction
% purposes:
basis=0; %used for different date time conventions for yearfrac
% Define the desired period of time:
desiredPeriod=(year(vix.Date)==1998&...
    datenum(vix.Date)>=datenum('1998-01-05','yyyy-mm-dd'));
ltcm=table(vix.Date(desiredPeriod),'VariableNames',{'dates'});
ltcm.datenum=datenum(ltcm.dates);
ltcm.vix=vix.vix(desiredPeriod);
ltcm.sp500=vix.sp500(desiredPeriod);
ltcm.sigma=vix.sigma(desiredPeriod);
ltcm.r=vix.r(desiredPeriod);
% find time to maturity at each date, then subsequent black scholes values:
for i=1:height(ltcm)
    T=datenum('2003-01-05','yyyy-mm-dd');
    ltcm.timeToMat(i)=yearfrac(ltcm.datenum(i),T,basis);
    X=1000;
    ltcm.delta(i)=blsdelta(ltcm.sp500(i),X,ltcm.r(i),...
        ltcm.timeToMat(i),ltcm.sigma(i));
    ltcm.gamma(i)=blsgamma(ltcm.sp500(i),X,ltcm.r(i),...
        ltcm.timeToMat(i),ltcm.sigma(i));
    ltcm.vega(i)=blsvega(ltcm.sp500(i),X,ltcm.r(i),...
        ltcm.timeToMat(i),ltcm.sigma(i));
    ltcm.moneyness(i)=ltcm.sp500(i)/X;
    ltcm.callPrice(i)=blsprice(ltcm.sp500(i),X,ltcm.r(i),...
        ltcm.timeToMat(i),ltcm.sigma(i));
end 
mrkp=0.2; % Markup of 20% applied to volatility
ltcm.ClientCallPrice=ltcm.callPrice;
ltcm.ClientCallPrice(1)=blsprice(ltcm.sp500(1),X,ltcm.r(1),...
    ltcm.timeToMat(1),ltcm.sigma(1)*(1+mrkp));

% cash position:
nmbr = 100000; % number of call options requested
ltcm.cash(1)=nmbr.*(ltcm.ClientCallPrice(1)-ltcm.delta(1)*ltcm.sp500(1));
for i=2:height(ltcm)
    ltcm.cash(i)=exp(ltcm.r(i-1)*...
        ((yearfrac(ltcm.datenum(i-1),ltcm.datenum(i),basis))))*ltcm.cash(i-1)...
        -nmbr.*(ltcm.delta(i)-ltcm.delta(i-1))*ltcm.sp500(i);
end

% hedge P&L:
dummyHedgePL=zeros(height(ltcm),1);
ltcm.hedgePL=zeros(height(ltcm),1);
dummyHedgePL(1)=nmbr.*(ltcm.ClientCallPrice(1)-ltcm.callPrice(1));
ltcm.hedgePL(1)=dummyHedgePL(1);
for i=2:height(ltcm)
    dummyHedgePL(i)=nmbr.*ltcm.delta(i-1)*(ltcm.sp500(i)-ltcm.sp500(i-1))+...
        (exp(ltcm.r(i-1)*(yearfrac(ltcm.datenum(i-1),ltcm.datenum(i),basis)))-1)...
        *(ltcm.cash(i-1));
    ltcm.hedgePL(i)=sum(dummyHedgePL(1:i));
end


% client P&L

% ASSUMPTION: No loss was recorded in the first day of client P&L. This is 
% because the client is only offered said price for an underwritten call 
% option on the S&P500 since the markup is implemented as the price paid 
% for the service of underwriting the options. Moreover, this is reflected 
% in the 2nd trading day?s client profit and loss column. 

dummyClientPL=zeros(height(ltcm),1);
ltcm.clientPL=zeros(height(ltcm),1);
for i=2:height(ltcm)
    dummyClientPL(i)=nmbr.*(ltcm.ClientCallPrice(i)-ltcm.ClientCallPrice(i-1));
    ltcm.clientPL(i)=sum(dummyClientPL(1:i));
end

% netPortfolioValue
for i=1:height(ltcm)
    assets(i)=nmbr*(ltcm.delta(i)*ltcm.sp500(i))+ltcm.cash(i);
    liabilities(i)=nmbr*ltcm.callPrice(i);
    ltcm.netPortfolioValue(i)=assets(i)-liabilities(i);
end

%% 3 - Plot
figure;
x1=plot(ltcm.datenum,ltcm.clientPL,'LineWidth',2);
datetick('x','yyyymmm');
hold on
x2=plot(ltcm.datenum,ltcm.hedgePL,'g-','LineWidth',2);
datetick('x','yyyymmm');
hold on
x3=plot(ltcm.datenum,ltcm.netPortfolioValue,'LineWidth',2);
legend([x1,x2,x3],{'ClientP&L','HedgeP&L','Cash Account'});
title('P&L Changes with the Cash Account over time');
ylabel('$');
xlabel('Time');
hold off

figure;
yyaxis left
x4=plot(ltcm.datenum,ltcm.delta,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Delta');
hold on
yyaxis right
x5=plot(ltcm.datenum,ltcm.sp500,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('S&P500 Index ($)');
legend([x4,x5],{'Delta','S&P500 Index'})
title('BS Delta Changes with S&P500 Index Price over time');
xlabel('Time');
hold off

figure;
yyaxis left
x6=plot(ltcm.datenum,ltcm.gamma,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Gamma');
hold on 
yyaxis right
x7=plot(ltcm.datenum,ltcm.moneyness,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Moneyness');
legend([x6,x7],{'BS Gamma','Moneyness'})
title('BS Gamma Changes with Moneyness over time');
xlabel('Time');
hold off

figure;
yyaxis left
x8=plot(ltcm.datenum,ltcm.vega,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Vega');
hold on
yyaxis right
x9=plot(ltcm.datenum,ltcm.vix,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('VIX');
legend([x8,x9],{'Vega','VIX'});
title('BS Vega Changes with the VIX Index over time');
xlabel('Time');
hold off

figure;
yyaxis left
x10=plot(ltcm.datenum,ltcm.r,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Interest Rate');
xlabel('Time');
hold on
yyaxis right
x11=plot(ltcm.datenum,ltcm.netPortfolioValue,'LineWidth',2);
datetick('x','yyyymmm');
ylabel('Net Portfolio Value ($)');
legend([x10,x11],{'Interest Rate','Net Portfolio Value'});
title('Net Portfolio Value and Interest Rate over Time');
hold off

figure;
yyaxis left
x12=plot(ltcm.datenum,ltcm.hedgePL,'LineWidth',2);
datetick('x','yyyymm');
hold on
yyaxis right
x13= plot(ltcm.datenum,ltcm.sp500,'LineWidth',2);
datetick('x','yyyymmm');
title('S&P500 and Hedge P&L over Time');
legend([x12,x13],{'Hedge P&L','S&P 500'});
hold off
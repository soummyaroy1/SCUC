SET
INTERVAL
BUS
GEN
PVGEN
WINDGEN
THERMALGEN
HYDROGEN
RESERVEGEN
GENPARAM
COSTCURVEPARAM
SYSPARAM
BLOCK
GENBLOCK
BRANCH
;

ALIAS (BUS,BUS2,BUS3);

SET
BRANCHBUS(BRANCH,*,*)  MAPPING OF BRANCH AND BUSES
GENBUS(BUS,*) MAPPING OF GENS AND THEIR BUSES
THERMALGENBUS(BUS,THERMALGEN)
RESERVEGENBUS(BUS,RESERVEGEN)
;

*DECLARE SCALARS
SCALAR
INTERVAL_LENGTH
NUMINTERVAL
RESERVETIME
VOLL
;

*DECLARE GEN AND MAIN PARAMETERS
PARAMETERS
SYSTEMVALUE
INTERVAL_MINUTES(*)
BLOCK_COST(*,*,*)
BLOCK_CAP(*,*,*)
NOLOADCOST(*,*)
STARTUPCOST(*,*)
RESERVECOST(*,*)
COST_CURVE(*,*)
LOAD(*)
LOADB(*,*)
GENVALUE(*,*,*)
VG_FORECAST(*,*)
;

*DECLARE RESERVE PARAMETERS
PARAMETERS
RESERVELEVEL(INTERVAL)
;

*NEW PARAMETERS
PARAMETERS
CAPACITY_FACTOR_PV(INTERVAL)
CAPACITY_FACTOR_WIND(INTERVAL)
RAMPRATE(*,*)
SURAMPRATE(*,*)
MINRUNTIME(*,THERMALGEN)
MINDOWNTIME(*,THERMALGEN)
INITIALONPERIOD(*,*)
INITIALOFFPERIOD(*,*)
INITIALSTATUS(*,*)
;

*TRANSMISSION PARAMETERS
PARAMETERS
REACTANCE(*,*,*) REACTANCE OF THE BRANCHES
FLOWLIMITS(*,*,*) LINEFLOW LIMITS
;

*SETS
$GDXIN GENERAL_MODEL_INPUT
$load GEN
$load BUS
$load PVGEN
$load WINDGEN
$load HYDROGEN
$load THERMALGEN
$load RESERVEGEN
$load GENPARAM
$load COSTCURVEPARAM
$load BLOCK
$load GENBLOCK
$load BRANCH

*COSTS
$GDXIN DASCUCINPUT1
$load BLOCK_COST
$load BLOCK_CAP
$load NOLOADCOST
$load STARTUPCOST
$load RESERVECOST
$load COST_CURVE
$load BRANCHBUS
$load GENBUS

*OP PARAMS
$GDXIN DASCUCINPUT2
$load INTERVAL_LENGTH
$load NUMINTERVAL
$load INTERVAL_MINUTES
$load GENVALUE
$load INTERVAL
$load LOAD
$load LOADB
$load VG_FORECAST
$load CAPACITY_FACTOR_PV
$load CAPACITY_FACTOR_WIND
$load RAMPRATE
$load SURAMPRATE
$load MINRUNTIME
$load MINDOWNTIME
$load RESERVETIME
$load INITIALONPERIOD
$load INITIALOFFPERIOD
$load INITIALSTATUS
$load REACTANCE
$load FLOWLIMITS
$load VOLL

ALIAS (INTERVAL,H);
ALIAS (GEN,G);

********************************** MIN RUN/DOWN TIME PARAMETERS*************

SET CHAR /CH1*CH2/;
PARAMETER UNIT(BUS,THERMALGEN,CHAR);
PARAMETER UNIT2(BUS,THERMALGEN,CHAR);
UNIT(BUS,THERMALGEN,'CH1') = NUMINTERVAL;
UNIT(BUS,THERMALGEN,'CH2') = (MINRUNTIME(BUS,THERMALGEN)-INITIALONPERIOD(BUS,THERMALGEN))*INITIALSTATUS(BUS,THERMALGEN);
PARAMETER GJ(BUS,THERMALGEN);
GJ(BUS,THERMALGEN) = SMIN(CHAR,UNIT(BUS,THERMALGEN,CHAR));
UNIT2(BUS,THERMALGEN,'CH1') = NUMINTERVAL;
UNIT2(BUS,THERMALGEN,'CH2') = (MINDOWNTIME(BUS,THERMALGEN)-INITIALOFFPERIOD(BUS,THERMALGEN))*(1-INITIALSTATUS(BUS,THERMALGEN));
PARAMETER FJ(BUS,THERMALGEN);
FJ(BUS,THERMALGEN) = SMIN(CHAR,UNIT2(BUS,THERMALGEN,CHAR));
*DISPLAY GJ,FJ;
********************************************************************************

*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
*DECLARE GEN AND MAIN VARIABLES
VARIABLES
PRODCOST
OPCOST_BY_INTERVAL(INTERVAL)
TOTAL_RESERVE(INTERVAL)
PNLS(*,INTERVAL)
LINEFLOW(*,*,*,INTERVAL)
;

POSITIVE VARIABLES
GEN_OPCOST_BY_INTERVAL(*,*,INTERVAL)
GEN_BLOCK_SCHEDULE(*,*,BLOCK,INTERVAL)
GEN_SCHEDULE(*,*,INTERVAL)
NOLOADCOST_BY_INTERVAL(INTERVAL)
STARTUPCOST_BY_INTERVAL(INTERVAL)
SHUTDOWNCOST_BY_INTERVAL(INTERVAL)
RESERVECOST_BY_INTERVAL(INTERVAL)
TLCOST(INTERVAL)
GEN_RESERVE_SCHEDULE(*,RESERVEGEN,INTERVAL)
BRANCH_SLACK1(BRANCH,INTERVAL)
BRANCH_SLACK2(BRANCH,INTERVAL)
;

VARIABLES
UNIT_STARTUP(*,*,INTERVAL)
UNIT_STATUS(*,*,INTERVAL)
UNIT_SHUTDOWN(*,*,INTERVAL)
;

VARIABLES
NET_INJECTION(*,INTERVAL)
SLACK1(BUS,INTERVAL)
;

VARIABLES
THETA(*,INTERVAL)
;

UNIT_STATUS.UP(BUS,GEN,INTERVAL) = 1;
UNIT_STATUS.LO(BUS,GEN,INTERVAL) = 0;
UNIT_STARTUP.UP(BUS,GEN,INTERVAL) = 1;
UNIT_STARTUP.LO(BUS,GEN,INTERVAL) = 0;
UNIT_SHUTDOWN.UP(BUS,GEN,INTERVAL) = 1;
UNIT_SHUTDOWN.LO(BUS,GEN,INTERVAL) = 0;
THETA.UP(BUS,INTERVAL) = 180;
THETA.LO(BUS,INTERVAL) = -180;
THETA.UP(BUS2,INTERVAL) = 180;
THETA.LO(BUS2,INTERVAL) = -180;

*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
*$ontext
EQUATIONS
OBJ1
OPCOSTA(INTERVAL)                                                                                                                    -
OPCOSTB(*,*,INTERVAL)
NLCOST(INTERVAL)
STUPCOST(INTERVAL)
RESCOST(INTERVAL)
TRANSCOST(INTERVAL)
Q_LOAD_BALANCE(INTERVAL) GENERATION GREATER THAN OR EQUAL TO LOAD
Q_GENTOTAL(*,*,INTERVAL)  TOTAL BLOCK GENERATION EQUALS SCHEDULE
Q_GEN_BLOCK_LIMIT1(*,*,BLOCK,INTERVAL)  FOR BLOCK 1
Q_GEN_BLOCK_LIMIT2(*,*,BLOCK,INTERVAL)  FOR OTHER BLOCKS
Q_GENLIMIT_HIGH(*,*,INTERVAL)  CAPACITY CONSTRAINT
Q_GENLIMIT_HIGH2(*,*,INTERVAL) CAPACITY CONSTRAINT WITH RESERVES
Q_VARIABLE_FORECAST_PV(*,*,INTERVAL) CAPACITY FACTOR CONSTRAINT
Q_VARIABLE_FORECAST_WIND(*,*,INTERVAL) CAPACITY FACTOR CONSTRAINT
Q_VARIABLE_FORECAST_HYDRO(*,*,INTERVAL) CAPACITY FACTOR CONSTRAINT
Q_RAMP_RATE_UP_BASIC(*,GEN,INTERVAL) RAMP UP LIMIT(SU)
Q_RAMP_RATE_DOWN_BASIC(*,GEN,INTERVAL) RAMP DOWN LIMIT
Q_RAMP_RATE_DOWN2(*,GEN,INTERVAL) SD RAMPS
Q_MIN_RUN_TIME(*,THERMALGEN,INTERVAL)  MIN RUN TIME CONSTRAINT
Q_MIN_RUN_TIME2(*,THERMALGEN,INTERVAL) MIN RUN TIME FOR ENDING INTERVALS
Q_UPTIME1(*,THERMALGEN) UT CONSTRAINT 1
Q_UPTIME2(*,THERMALGEN) UT CONSTRAINT 2
Q_UPTIME3(*,THERMALGEN,INTERVAL) UT CONSTRAINT 3
Q_DNTIME1(*,THERMALGEN) DT CONSTRAINT 1
Q_DNTIME2(*,THERMALGEN) DT CONSTRAINT 2
Q_DNTIME3(*,THERMALGEN,INTERVAL) DT CONSTAINT 3
Q_COMMITMENT_HARD_HI(*,GEN,INTERVAL)
Q_COMMITMENT_HARD_LO(*,GEN,INTERVAL)
Q_STARTUP(*,GEN,INTERVAL)  TO DETERMINE STARTUP SHUTDOWN VARIABLES
Q_STARTUP2(*,GEN,INTERVAL) TO DETERMINE STARTUP SHUTDOWN VARIABLES FOR INTERVAL 0
Q_STARTUP3(*,GEN,INTERVAL) MAKE SURE UNIT CANNOT SU AND SD SIMULTANEOUSLY
Q_RESERVE_CAPABILITY1(*,RESERVEGEN,INTERVAL) RESERVE SCHEDULE LIES WITHIN UPPER LIMIT
Q_RESERVE_TOTAL(INTERVAL)
Q_RESERVE_BALANCE1(INTERVAL) SUM OF RESERVES EQUAL(OR GREATER) TO REQUIREMENT
Q_RESERVE_BALANCE2(INTERVAL) SUM OF RESERVES IS LESSER(OR EQUAL) TO MAX ALLOWABLE RESERVE CAPACITY
Q_RESERVE_RAMPUP_LIMIT(*,RESERVEGEN,INTERVAL) RESERVE RAMPUP LIMIT
*Q_NETINJ(BUS,INTERVAL) NET INJECTION AT EACH BUS
*Q_POWBAL2(*,INTERVAL)
*Q_FLOWCALC(BRANCH,BUS,BUS2,INTERVAL) DC PF EQUATION
*Q_MAXFLOW(BRANCH,BUS,BUS2,INTERVAL) MAX FLOW
*Q_MINFLOW(BRANCH,BUS,BUS2,INTERVAL) MIN FLOW
;

OBJ1..
PRODCOST =E= SUM(INTERVAL, OPCOST_BY_INTERVAL(INTERVAL)+NOLOADCOST_BY_INTERVAL(INTERVAL)+STARTUPCOST_BY_INTERVAL(INTERVAL)+RESERVECOST_BY_INTERVAL(INTERVAL))
;

OPCOSTA(INTERVAL)..
OPCOST_BY_INTERVAL(INTERVAL) =E= SUM((BUS,GEN)$(GENBUS(BUS,GEN)), GEN_OPCOST_BY_INTERVAL(BUS,GEN,INTERVAL))
;

OPCOSTB(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN))..
GEN_OPCOST_BY_INTERVAL(BUS,GEN,INTERVAL) =E= SUM(BLOCK, BLOCK_COST(BUS,GEN,BLOCK)*GEN_BLOCK_SCHEDULE(BUS,GEN,BLOCK,INTERVAL))
;

NLCOST(INTERVAL)..
NOLOADCOST_BY_INTERVAL(INTERVAL) =E= SUM((BUS,THERMALGEN)$(GENBUS(BUS,THERMALGEN)), UNIT_STATUS(BUS,THERMALGEN,INTERVAL)*NOLOADCOST(BUS,THERMALGEN)*GENVALUE(BUS,THERMALGEN,"CAPACITY"))
;

STUPCOST(INTERVAL)..
STARTUPCOST_BY_INTERVAL(INTERVAL) =E= SUM((BUS,GEN)$(GENBUS(BUS,GEN)), UNIT_STARTUP(BUS,GEN,INTERVAL)*STARTUPCOST(BUS,GEN))
;

RESCOST(INTERVAL)..
RESERVECOST_BY_INTERVAL(INTERVAL) =E= SUM((BUS,RESERVEGEN)$(GENBUS(BUS,RESERVEGEN)), GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL)*RESERVECOST(BUS,RESERVEGEN))
;

*$ontext
TRANSCOST(INTERVAL)..
TLCOST(INTERVAL) =E= SUM(BUS, (VOLL*SLACK1(BUS,INTERVAL)))/1E6;
;
*$offtext

Q_LOAD_BALANCE(INTERVAL)..
SUM((BUS,GEN)$(GENBUS(BUS,GEN)),GEN_SCHEDULE(BUS,GEN,INTERVAL)) =G= LOAD(INTERVAL)
;

Q_GENTOTAL(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN))..
GEN_SCHEDULE(BUS,GEN,INTERVAL) =E= SUM(BLOCK,GEN_BLOCK_SCHEDULE(BUS,GEN,BLOCK,INTERVAL))
;

Q_GEN_BLOCK_LIMIT1(BUS,GEN,BLOCK,INTERVAL)$(ORD(BLOCK) EQ 1 AND GENBUS(BUS,GEN))..
GEN_BLOCK_SCHEDULE(BUS,GEN,BLOCK,INTERVAL) =L= BLOCK_CAP(BUS,GEN,BLOCK)
;

Q_GEN_BLOCK_LIMIT2(BUS,GEN,BLOCK,INTERVAL)$(ORD(BLOCK) GT 1 AND GENBUS(BUS,GEN))..
GEN_BLOCK_SCHEDULE(BUS,GEN,BLOCK,INTERVAL) =L= BLOCK_CAP(BUS,GEN,BLOCK) - BLOCK_CAP(BUS,GEN,BLOCK-1)
;

Q_GENLIMIT_HIGH(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN))..
GEN_SCHEDULE(BUS,GEN,INTERVAL) =L= GENVALUE(BUS,GEN,"CAPACITY")*UNIT_STATUS(BUS,GEN,INTERVAL);
;

Q_GENLIMIT_HIGH2(BUS,RESERVEGEN,INTERVAL)$(GENBUS(BUS,RESERVEGEN))..
GEN_SCHEDULE(BUS,RESERVEGEN,INTERVAL) + GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL) =L= UNIT_STATUS(BUS,RESERVEGEN,INTERVAL)*GENVALUE(BUS,RESERVEGEN,"CAPACITY")
;

Q_VARIABLE_FORECAST_PV(BUS,PVGEN,INTERVAL)$(GENBUS(BUS,PVGEN))..
GEN_SCHEDULE(BUS,PVGEN,INTERVAL) =L= GENVALUE(BUS,PVGEN,"CAPACITY")*CAPACITY_FACTOR_PV(INTERVAL)
;

Q_VARIABLE_FORECAST_WIND(BUS,WINDGEN,INTERVAL)$(GENBUS(BUS,WINDGEN))..
GEN_SCHEDULE(BUS,WINDGEN,INTERVAL) =L= GENVALUE(BUS,WINDGEN,"CAPACITY")*CAPACITY_FACTOR_WIND(INTERVAL)
;

Q_VARIABLE_FORECAST_HYDRO(BUS,HYDROGEN,INTERVAL)$(GENBUS(BUS,HYDROGEN))..
GEN_SCHEDULE(BUS,HYDROGEN,INTERVAL) =L= GENVALUE(BUS,HYDROGEN,"CAPACITY")*0.4
;

Q_RAMP_RATE_UP_BASIC(BUS,GEN,INTERVAL)$(ORD(INTERVAL) GT 1 AND GENBUS(BUS,GEN))..
GEN_SCHEDULE(BUS,GEN,INTERVAL) - GEN_SCHEDULE(BUS,GEN,INTERVAL-1) =L= (RAMPRATE(BUS,GEN)*60*UNIT_STATUS(BUS,GEN,INTERVAL-1) + UNIT_STARTUP(BUS,GEN,INTERVAL)*SURAMPRATE(BUS,GEN)*60)
;

Q_RAMP_RATE_DOWN_BASIC(BUS,GEN,INTERVAL)$(ORD(INTERVAL) GT 1 AND GENBUS(BUS,GEN))..
GEN_SCHEDULE(BUS,GEN,INTERVAL) - GEN_SCHEDULE(BUS,GEN,INTERVAL-1) =G= -1* (RAMPRATE(BUS,GEN)*60*UNIT_STATUS(BUS,GEN,INTERVAL-1))
;

Q_RAMP_RATE_DOWN2(BUS,GEN,INTERVAL)$(ORD(INTERVAL) LT NUMINTERVAL AND GENBUS(BUS,GEN))..
GEN_SCHEDULE(BUS,GEN,INTERVAL) =L= (UNIT_STATUS(BUS,GEN,INTERVAL)-UNIT_SHUTDOWN(BUS,GEN,INTERVAL+1))*GENVALUE(BUS,GEN,"CAPACITY") +  UNIT_SHUTDOWN(BUS,GEN,INTERVAL)*SURAMPRATE(BUS,GEN)*60
;

Q_MIN_RUN_TIME(BUS,THERMALGEN,INTERVAL)$(ORD(INTERVAL) LE CARD(INTERVAL)-MINRUNTIME(BUS,THERMALGEN)+1 AND GENBUS(BUS,THERMALGEN))..
SUM(H$((ORD(H) GE ORD(INTERVAL)) AND (ORD(H) LE ORD(INTERVAL)+MINRUNTIME(BUS,THERMALGEN)-1)),UNIT_STATUS(BUS,THERMALGEN,INTERVAL))
         =G= MINRUNTIME(BUS,THERMALGEN)*(UNIT_STATUS(BUS,THERMALGEN,INTERVAL) - UNIT_STATUS(BUS,THERMALGEN,INTERVAL-1))
;

Q_MIN_RUN_TIME2(BUS,THERMALGEN,INTERVAL)$(ORD(INTERVAL) GE CARD(INTERVAL)-MINRUNTIME(BUS,THERMALGEN)+2 AND GENBUS(BUS,THERMALGEN))..
SUM(H$((ORD(H) GE (ORD(INTERVAL))) AND (ORD(H) LE CARD(INTERVAL))),UNIT_STATUS(BUS,THERMALGEN,H))
         =G= (CARD(INTERVAL) - ORD(INTERVAL)+1)* (UNIT_STATUS(BUS,THERMALGEN,INTERVAL) - UNIT_STATUS(BUS,THERMALGEN,INTERVAL-1))
;

************************************** NEW MRT/MDT EQNS(1/6)************************

Q_UPTIME1(BUS,THERMALGEN)$(GJ(BUS,THERMALGEN)>0 AND GENBUS(BUS,THERMALGEN))..
SUM(INTERVAL$(ORD(INTERVAL) LE GJ(BUS,THERMALGEN)),1-UNIT_STATUS(BUS,THERMALGEN,INTERVAL)) =E= 0
;

Q_UPTIME2(BUS,THERMALGEN)$(MINRUNTIME(BUS,THERMALGEN)>1 AND GENBUS(BUS,THERMALGEN))..
SUM(INTERVAL$(ORD(INTERVAL) > NUMINTERVAL-MINRUNTIME(BUS,THERMALGEN)+1),UNIT_STATUS(BUS,THERMALGEN,INTERVAL)-UNIT_STARTUP(BUS,THERMALGEN,INTERVAL)) =G= 0
;

Q_UPTIME3(BUS,THERMALGEN,INTERVAL)$(GENBUS(BUS,THERMALGEN) AND ORD(INTERVAL)>GJ(BUS,THERMALGEN) AND ORD(INTERVAL)<NUMINTERVAL-MINRUNTIME(BUS,THERMALGEN)+2 AND NOT(GJ(BUS,THERMALGEN)>NUMINTERVAL-MINRUNTIME(BUS,THERMALGEN)))..
SUM(H$((ORD(H)>ORD(INTERVAL)-1) AND (ORD(H)<ORD(INTERVAL)+MINRUNTIME(BUS,THERMALGEN))),UNIT_STATUS(BUS,THERMALGEN,INTERVAL)) =G= MINRUNTIME(BUS,THERMALGEN)*UNIT_STARTUP(BUS,THERMALGEN,INTERVAL)
;

Q_DNTIME1(BUS,THERMALGEN)$(FJ(BUS,THERMALGEN)>0 AND GENBUS(BUS,THERMALGEN))..
SUM(INTERVAL$(ORD(INTERVAL) LE FJ(BUS,THERMALGEN)),UNIT_STATUS(BUS,THERMALGEN,INTERVAL)) =E= 0
;

Q_DNTIME2(BUS,THERMALGEN)$(MINDOWNTIME(BUS,THERMALGEN)>1 AND GENBUS(BUS,THERMALGEN))..
SUM(INTERVAL$(ORD(INTERVAL) > NUMINTERVAL-MINDOWNTIME(BUS,THERMALGEN)+1),1-UNIT_STATUS(BUS,THERMALGEN,INTERVAL)-UNIT_SHUTDOWN(BUS,THERMALGEN,INTERVAL)) =G= 0
;

Q_DNTIME3(BUS,THERMALGEN,INTERVAL)$(GENBUS(BUS,THERMALGEN) AND ORD(INTERVAL)>FJ(BUS,THERMALGEN) AND ORD(INTERVAL)<NUMINTERVAL-MINDOWNTIME(BUS,THERMALGEN)+2 AND NOT(FJ(BUS,THERMALGEN)>NUMINTERVAL-MINDOWNTIME(BUS,THERMALGEN)))..
SUM(H$((ORD(H)>ORD(INTERVAL)-1) AND (ORD(H)<ORD(INTERVAL)+MINDOWNTIME(BUS,THERMALGEN))),1-UNIT_STATUS(BUS,THERMALGEN,INTERVAL)) =G= MINDOWNTIME(BUS,THERMALGEN)*UNIT_SHUTDOWN(BUS,THERMALGEN,INTERVAL)
;

***********************************************************************************
Q_COMMITMENT_HARD_HI(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN))..
UNIT_STATUS(BUS,GEN,INTERVAL) =G= 0
;

Q_COMMITMENT_HARD_LO(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN))..
UNIT_STATUS(BUS,GEN,INTERVAL) =L= 1
;

Q_STARTUP(BUS,GEN,INTERVAL)$(ORD(INTERVAL) GT 1 AND GENBUS(BUS,GEN))..
UNIT_STARTUP(BUS,GEN,INTERVAL) - UNIT_SHUTDOWN(BUS,GEN,INTERVAL) =E= UNIT_STATUS(BUS,GEN,INTERVAL) - UNIT_STATUS(BUS,GEN,INTERVAL-1)
;

Q_STARTUP2(BUS,GEN,INTERVAL)$(ORD(INTERVAL) EQ 1 AND GENBUS(BUS,GEN))..
UNIT_STARTUP(BUS,GEN,INTERVAL) - UNIT_SHUTDOWN(BUS,GEN,INTERVAL) =E= UNIT_STATUS(BUS,GEN,INTERVAL) - GENVALUE(BUS,GEN,"INITIAL_STATUS")
;

Q_STARTUP3(BUS,GEN,INTERVAL)$(GENBUS(BUS,GEN)) ..
UNIT_STARTUP(BUS,GEN,INTERVAL) + UNIT_SHUTDOWN(BUS,GEN,INTERVAL) =L= 1
;

*$$$$$$$$$$$$ RESERVES $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
Q_RESERVE_CAPABILITY1(BUS,RESERVEGEN,INTERVAL)$(GENBUS(BUS,RESERVEGEN))..
GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL) =L= GENVALUE(BUS,RESERVEGEN,"CAPACITY") - GEN_SCHEDULE(BUS,RESERVEGEN,INTERVAL)
;

$ontext
Q_RESERVE_CAPABILITY2(BUS,RESERVEGEN,INTERVAL)$(GENBUS(BUS,RESERVEGEN))..
GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL) =L=
;
$offtext

Q_RESERVE_TOTAL(INTERVAL)..
TOTAL_RESERVE(INTERVAL) =E= SUM((BUS,RESERVEGEN)$(GENBUS(BUS,RESERVEGEN)),GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL))
;

Q_RESERVE_BALANCE1(INTERVAL)..
TOTAL_RESERVE(INTERVAL) =G= 0.02 * LOAD(INTERVAL)
;

Q_RESERVE_BALANCE2(INTERVAL)..
TOTAL_RESERVE(INTERVAL) =L= .1*SUM((BUS,RESERVEGEN)$(GENBUS(BUS,RESERVEGEN)),GENVALUE(BUS,RESERVEGEN,"CAPACITY"))
;

Q_RESERVE_RAMPUP_LIMIT(BUS,RESERVEGEN,INTERVAL)$(ORD(INTERVAL) GT 1 AND GENBUS(BUS,RESERVEGEN))..
(GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL)-GEN_RESERVE_SCHEDULE(BUS,RESERVEGEN,INTERVAL-1))/(RESERVETIME/60) =L= RAMPRATE(BUS,RESERVEGEN)*60*UNIT_STATUS(BUS,RESERVEGEN,INTERVAL)
;

$ontext
*$$$$$$$$$$$$$$$$$$ TRANSMISSION CONSTRAINTS(2/5) $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
Q_NETINJ(BUS,INTERVAL)..
-SUM(BRANCHBUS(BRANCH,BUS,BUS2),LINEFLOW(BRANCHBUS,INTERVAL))+SUM(BRANCHBUS(BRANCH,BUS2,BUS),LINEFLOW(BRANCHBUS,INTERVAL)) +  SUM(GENBUS(BUS,GEN),GEN_SCHEDULE(GENBUS,INTERVAL)) =E= LOADB(BUS,INTERVAL) + SLACK1(BUS,INTERVAL);
;
THETA.FX("10011", INTERVAL)=0;

Q_POWBAL2(BUS,INTERVAL)..
NET_INJECTION(BUS,INTERVAL) =G= LOADB(BUS,INTERVAL) - PNLS(BUS,INTERVAL)
;


Q_FLOWCALC(BRANCHBUS(BRANCH,BUS,BUS2),INTERVAL)..
REACTANCE(BRANCH,BUS,BUS2)*LINEFLOW(BRANCH,BUS,BUS2,INTERVAL) =E= THETA(BUS,INTERVAL) - THETA(BUS2,INTERVAL)
;

Q_MINFLOW(BRANCHBUS(BRANCH,BUS,BUS2),INTERVAL)..
LINEFLOW(BRANCH,BUS,BUS2,INTERVAL) =G= -1*FLOWLIMITS(BRANCH,BUS,BUS2)
;

Q_MAXFLOW(BRANCHBUS(BRANCH,BUS,BUS2),INTERVAL)..
LINEFLOW(BRANCH,BUS,BUS2,INTERVAL) =L= FLOWLIMITS(BRANCH,BUS,BUS2)
;
$offtext
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

*$ontext
MODEL SCUC/
OBJ1
OPCOSTA
OPCOSTB
NLCOST
STUPCOST
RESCOST
TRANSCOST
Q_LOAD_BALANCE
Q_GENTOTAL
Q_GEN_BLOCK_LIMIT1
Q_GEN_BLOCK_LIMIT2
Q_GENLIMIT_HIGH
Q_GENLIMIT_HIGH2
Q_VARIABLE_FORECAST_PV
Q_VARIABLE_FORECAST_WIND
Q_VARIABLE_FORECAST_HYDRO
Q_RAMP_RATE_UP_BASIC
Q_RAMP_RATE_DOWN_BASIC
Q_RAMP_RATE_DOWN2
Q_MIN_RUN_TIME
Q_MIN_RUN_TIME2
Q_UPTIME1
Q_UPTIME2
Q_UPTIME3
Q_DNTIME1
Q_DNTIME2
Q_DNTIME3
Q_COMMITMENT_HARD_HI
Q_COMMITMENT_HARD_LO
Q_STARTUP
Q_STARTUP2
Q_STARTUP3
Q_RESERVE_CAPABILITY1
Q_RESERVE_TOTAL
Q_RESERVE_BALANCE1
Q_RESERVE_BALANCE2
Q_RESERVE_RAMPUP_LIMIT
*Q_NETINJ
*Q_POWBAL2
*Q_FLOWCALC
*Q_MINFLOW
*Q_MAXFLOW
/;


SCUC.iterlim =5000000;
SCUC.optcr = 0.01;
SCUC.reslim = 18000;
option solvelink=0;
SCUC.optfile = 1;
heaplimit = 200000000;
Option limrow= 1000;


SOLVE SCUC USING MIP MINIMIZING PRODCOST;


EXECUTE_UNLOAD 'SCUCRESULTS',GEN_BLOCK_SCHEDULE,GEN_SCHEDULE,GEN_RESERVE_SCHEDULE,GEN_OPCOST_BY_INTERVAL,NOLOADCOST_BY_INTERVAL,STARTUPCOST_BY_INTERVAL,RESERVECOST_BY_INTERVAL;
*SCUC.savepoint = 2;
*Option MIP = cplex;
*EXECUTE '=GDX2ACCESS SCUCRESULTS.GDX'
*$offtext
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$ post processing $$$$$$$$$$$$$$$$$$$$$$$$$$$
*$ontext
*PARAMETER CONGESTIONCOST;
*CONGESTIONCOST = SUM((BRANCH,BUS,BUS2,INTERVAL),LINEFLOW.L(BRANCH,BUS,BUS2,INTERVAL)*(Q_FLOWCALC.M(BRANCH,BUS,BUS2,INTERVAL)+ Q_NETINJ.M(BUS,INTERVAL)))/(2*1E6);
*DISPLAY CONGESTIONCOST;
*$offtext
*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$




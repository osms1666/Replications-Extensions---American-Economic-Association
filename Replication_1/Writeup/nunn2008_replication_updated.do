/*==============================================================================
  REPLICATION: Nunn (2008) "The Long-Term Effects of Africa's Slave Trades"
                Quarterly Journal of Economics, February 2008

  PURPOSE:
    This DO file replicates the main figures and tables from Nunn (2008),
    which examines the causal relationship between Africa's historical
    slave trades and current economic underdevelopment.

    We replicate:
      - Figure 3  : Scatter plot of slave exports vs. log GDP per capita
      - Table  3  : OLS regressions (6 specifications)
      - Table  4  : IV / 2SLS regressions (4 specifications)
      - Figure 6  : Slave exports vs. ethnic fractionalization
      - Figure 7  : Slave exports vs. 19th-century state development
      - Figure 8  : Paths of economic development since 1950 (bonus)

  DATA:
    slave_trade_QJE.dta  —  available from Nathan Nunn's website
    (also provided alongside this replication package)

  SOFTWARE:  Stata 14 or later recommended
             (ivreg2 and ranktest may need to be installed; see below)

  AUTHORS OF REPLICATION:  [Your names here]
  DATE:       February 2026
==============================================================================*/


/*------------------------------------------------------------------------------
  SECTION 0: HOUSEKEEPING
  ------------------------------------------------------------------------------
  Before anything else we clear memory, set preferences, and point Stata
  to our data.  Good practice at the top of every DO file.
------------------------------------------------------------------------------*/

  clear all            // clear any data currently loaded in memory
  set more off         // stop Stata pausing output at each screenful
  capture log close    // close any log file that might already be open

  * ---------- user-defined path: change this to wherever you saved the data ---
  global datapath "/mnt/user-data/uploads"
  global outpath  "/mnt/user-data/outputs"
  * ---------------------------------------------------------------------------

  log using "$outpath/nunn2008_replication.log", replace text

  use "$datapath/slave_trade_QJE.dta", clear

  * Quick inventory of the data
  describe          // shows variable names, types, and labels
  summarize         // shows N, mean, sd, min, max for every variable


/*------------------------------------------------------------------------------
  SECTION 1: UNDERSTANDING THE KEY VARIABLES
  ------------------------------------------------------------------------------
  Before jumping into regressions it is essential to know what each variable
  represents.  Below we list the variables we will use most heavily.

  DEPENDENT VARIABLE
  ------------------
  ln_maddison_pcgdp2000
      Natural log of real per-capita GDP in the year 2000, from Maddison
      (2003).  Logging income is standard in cross-country regressions
      because the distribution of raw GDP is heavily right-skewed.

  MAIN REGRESSOR
  --------------
  ln_export_area
      Natural log of total slaves exported between 1400–1900 (all four
      slave trades combined), divided by land area.  Dividing by area
      controls for country size: a large country exporting 1 million
      slaves is different from a small country doing so.

      NOTE: For countries that exported ZERO slaves Nunn uses 0.1 (before
      logging) so that ln(0) is avoided.  This is disclosed in footnote 7.

  COLONIZER FIXED EFFECTS  (colony0 – colony7)
  -----------------------------------------------
  Indicator (dummy) variables for which colonial power ruled the country
  before independence.  Including these absorbs variation in outcomes that
  is common across all colonies of, say, Britain or France, ensuring that
  our slave-trade coefficient is not confounded by differences in colonial
  institutions.

  GEOGRAPHY CONTROLS
  ------------------
  abs_latitude    Distance from the equator (absolute value of latitude).
                  Tropical countries tend to have worse disease environments
                  and lower agricultural productivity.
  longitude       East-west position.  Controls for differences between
                  the Atlantic-facing west and the Indian-Ocean-facing east.
  rain_min        Lowest monthly rainfall (mm).  Proxy for aridity.
  humid_max       Average maximum afternoon humidity in the hottest month.
  low_temp        Average minimum monthly temperature (°C).
  ln_coastline_area  ln(coastline / land area).  Countries with longer
                  coastlines relative to their size have better access to
                  international trade routes.

  ADDITIONAL CONTROLS (Table 3, cols 4-6)
  ----------------------------------------
  island_dum      = 1 for island countries (e.g. Mauritius, Seychelles).
  islam           % of population that is Muslim.
  legor_fr        = 1 if French civil-law legal origin.
  region_n/s/w/e/c  Fixed effects for five African sub-regions.
  ln_avg_gold_pop  ln(avg annual gold production per capita, 1970-2000).
  ln_avg_oil_pop   ln(avg annual oil production per capita, 1970-2000).
  ln_avg_all_diamonds_pop  ln(avg annual diamond production per capita).

  INSTRUMENTAL VARIABLES (Table 4)
  ----------------------------------
  atlantic_distance_minimum  Sailing distance to nearest major Atlantic-
                             trade destination (9 biggest slave importers).
  indian_distance_minimum    Sailing distance to nearest Indian Ocean
                             trade destination (Mauritius or Muscat).
  saharan_distance_minimum   Overland distance to nearest trans-Saharan
                             slave port (Algiers, Tunis, Tripoli, etc.).
  red_sea_distance_minimum   Overland distance to nearest Red Sea port.

  CHANNEL VARIABLES (Figures 6 & 7)
  -----------------------------------
  ethnic_fractionalization  Probability that two randomly chosen citizens
                            belong to different ethnic groups (Alesina 2003).
  state_dev                 Proportion of a country's indigenous population
                            belonging to ethnicities with centralized
                            pre-colonial political structures (Gennaioli &
                            Rainer 2006).  Higher = more developed states.
------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------
  SECTION 2: SUMMARY STATISTICS  (replicates Table A.1 in the Appendix)
  ------------------------------------------------------------------------------
  'tabstat' produces a compact table of descriptive statistics.
  We match the exact variables and order shown in Nunn's Appendix Table A.1.
------------------------------------------------------------------------------*/

  * Define the variable list exactly as in the paper
  local sumvars ///
      ln_maddison_pcgdp2000 ln_export_area ln_export_pop           ///
      abs_latitude longitude rain_min humid_max low_temp            ///
      ln_coastline_area island_dum islam legor_fr                   ///
      ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop        ///
      atlantic_distance_minimum indian_distance_minimum             ///
      saharan_distance_minimum red_sea_distance_minimum

  tabstat `sumvars', ///
      statistics(mean sd min max n) ///
      columns(statistics)           ///
      format(%9.2f)
  /*
  READING THE OUTPUT:
    Each row is one variable.  Columns show mean, standard deviation,
    minimum, maximum, and number of (non-missing) observations.
    With N=52 African countries across all specifications, we expect 52
    observations for most variables.
  */


/*------------------------------------------------------------------------------
  SECTION 3: FIGURE 3 — Scatter plot of slave exports vs. income
  ------------------------------------------------------------------------------
  Figure 3 in the paper shows a simple bivariate scatter of:
    x-axis: ln(exports/area)  — log slave exports per square km
    y-axis: ln y              — log real per-capita GDP in 2000

  The fitted line comes from a simple OLS regression of y on x (no controls).
  Nunn labels each dot with the country's ISO code.

  Stata commands used:
    twoway (scatter ...) (lfit ...)
      - scatter: creates the dot-plot
      - lfit   : overlays the OLS fitted line
    mlabel()   : places text labels (ISO codes) next to each point
    mlabsize() : controls label font size
    xlabel/ylabel: axis tick marks
    note()     : adds the coefficient / SE / N / R² note at the bottom
------------------------------------------------------------------------------*/

  * First run the simple bivariate OLS to get the numbers for the figure note
  quietly reg ln_maddison_pcgdp2000 ln_export_area
  local coef  = string(_b[ln_export_area], "%6.3f")
  local se    = string(_se[ln_export_area], "%5.3f")
  local N     = e(N)
  local r2    = string(e(r2), "%4.2f")

  twoway ///
      (scatter ln_maddison_pcgdp2000 ln_export_area,                 ///
          mlabel(isocode) mlabsize(tiny) mlabposition(3)             ///
          msymbol(none)                                               ///
          mcolor(gs6))                                                ///
      (lfit ln_maddison_pcgdp2000 ln_export_area,                    ///
          lcolor(black) lwidth(medium)),                              ///
      ytitle("Log real per capita GDP in 2000, ln y")                 ///
      xtitle("ln(exports/area)")                                      ///
      title("Figure 3: Slave Exports and Income")                     ///
      note("(coef = `coef', s.e. = `se', N = `N', R{superscript:2} = `r2')", ///
           size(small))                                               ///
      legend(off)                                                     ///
      scheme(s1mono)
  /*
  KEY CHOICES EXPLAINED:
    msymbol(none): we use only the country labels (no filled circles)
                   so the plot does not get cluttered — matching the paper.
    lfit:          Stata draws the OLS prediction line automatically.
    The `coef', `se', etc. are Stata "local macros" — think of them as
    named placeholders we filled in right after running the regression.
  */

  graph export "$outpath/figure3_scatter.png", replace width(1200)
  di "Figure 3 exported."


/*------------------------------------------------------------------------------
  SECTION 4: TABLE 3 — OLS Estimates (all six columns)
  ------------------------------------------------------------------------------
  The core OLS estimating equation (Nunn equation 1) is:

      ln(y_i) = β0 + β1 * ln(exports_i/area_i) + C_i'δ + X_i'γ + ε_i

  where:
    ln(y_i)                = log real per-capita GDP in 2000
    ln(exports_i/area_i)   = log slave exports normalized by land area
    C_i                    = vector of colonizer-identity dummies
    X_i                    = vector of geographic / other controls
    ε_i                    = error term (assumed i.i.d. for OLS)

  Nunn estimates six nested specifications:
    Col (1): colonizer FE only
    Col (2): + geography controls
    Col (3): col (2) but RESTRICT sample (drop islands & North Africa)
    Col (4): + island dummy, % Islamic, French legal origin, North Africa FE
    Col (5): + natural resource production controls
    Col (6): col (5) but restricted sample

  We use 'reg' for OLS and 'vce(robust)' is NOT used by default (Nunn
  reports conventional standard errors).  We store each result with
  'estimates store' so we can tabulate them together at the end.

  Colonizer dummies:  colony0 – colony7 capture which colonial power
  controlled each country.  We include them as a group using 'i.colony*'
  syntax or by listing all dummies.  We will use the variable name
  approach to be explicit.
------------------------------------------------------------------------------*/

  * ---- COLONIZER DUMMIES: list them explicitly ----
  * The data has colony0 colony1 ... colony7 (8 categories).
  * We drop one as the base category (Stata does this automatically
  * when we list them all since one will be collinear with the intercept).
  * We use 'colony1-colony7' and let colony0 be the omitted group.

  * Check which colonizer codes exist
  tab colony0
  * (you can do the same for colony1-colony7 to see the breakdown)

  local colony_fe "colony1 colony2 colony3 colony4 colony5 colony6 colony7"

  local geo_controls ///
      abs_latitude longitude rain_min humid_max low_temp ln_coastline_area

  * ---------- Column (1): Colonizer FE only ----------
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe'
  /*
  'reg y x controls' runs OLS.  Stata prints:
    - Number of observations
    - F-statistic testing all slopes = 0
    - R-squared and Adjusted R-squared
    - For each variable: coefficient, standard error, t-statistic, p-value,
      and 95% confidence interval.
  The coefficient on ln_export_area is our β1 of interest.
  */
  estimates store col1   // store results under the name "col1"

  * ---------- Column (2): + geography controls ----------
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe' `geo_controls'
  estimates store col2

  * ---------- Column (3): geography + restricted sample ----------
  * Drop island countries and North African countries.
  * North Africa: Morocco(MAR), Algeria(DZA), Tunisia(TUN), Libya(LBY),
  *               Egypt(EGY)
  * Islands: Seychelles(SYC), Mauritius(MUS), Comoros(COM),
  *          Sao Tome & Principe(STP), Cape Verde(CPV)
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe' `geo_controls' ///
      if island_dum==0 & ///
         !inlist(isocode,"MAR","DZA","TUN","LBY","EGY",               ///
                         "SYC","MUS","COM","STP","CPV")
  estimates store col3

  * ---------- Column (4): + island/Islam/legal/N.Africa indicators ----------
  * 'islam'    captures that North Africa is predominantly Muslim
  * 'legor_fr' captures that North Africa uses French civil law
  * We also add a North Africa indicator and an island indicator
  * NOTE: 'region_n' is the North Africa region dummy in the data
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe' `geo_controls' ///
      island_dum islam legor_fr region_n
  estimates store col4

  * ---------- Column (5): + natural resources ----------
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe' `geo_controls' ///
      island_dum islam legor_fr region_n                               ///
      ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop
  estimates store col5

  * ---------- Column (6): full controls + restricted sample ----------
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe' `geo_controls' ///
      ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop           ///
      if island_dum==0 &                                               ///
         !inlist(isocode,"MAR","DZA","TUN","LBY","EGY",               ///
                         "SYC","MUS","COM","STP","CPV")
  estimates store col6

  /*
  DISPLAYING RESULTS SIDE-BY-SIDE WITH 'esttab' or 'estimates table'
  -------------------------------------------------------------------
  'estimates table' is base Stata; 'esttab' (from the ssc estout package)
  gives prettier output.  We use estimates table for portability.

  'keep(ln_export_area)' shows only the slave-trade coefficient; you can
  remove this to see all coefficients.  'stats(N r2)' adds obs and R².
  'b(%9.3f) se star' shows coefficients, standard errors, and stars.
  */
  di ""
  di "=========================================================="
  di "TABLE 3: OLS — Relationship Between Slave Exports & Income"
  di "=========================================================="

  estimates table col1 col2 col3 col4 col5 col6, ///
      keep(ln_export_area `geo_controls' island_dum islam legor_fr ///
           ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop)  ///
      b(%9.3f) se(%9.3f) stats(N r2)                               ///
      star(* 0.10 ** 0.05 *** 0.01)                                ///
      title("Table 3: OLS Estimates")
  /*
  READING THE STARS:
    * = significant at the 10% level (p < 0.10)
   ** = significant at the 5% level  (p < 0.05)
  *** = significant at the 1% level  (p < 0.01)

  Nunn's paper shows ln_export_area is negative and significant across
  all six columns, ranging from about -0.076 to -0.128.
  */


/*------------------------------------------------------------------------------
  SECTION 5: TABLE 4 — IV / 2SLS Estimates
  ------------------------------------------------------------------------------
  WHY INSTRUMENTAL VARIABLES?
  ---------------------------
  OLS could be biased for two reasons:
  (a) REVERSE CAUSALITY / SELECTION: Maybe initially richer areas selected
      into the slave trade.  We showed this is a concern — but selection was
      by initially RICHER areas, so OLS is biased TOWARD ZERO.
  (b) MEASUREMENT ERROR: Slaves from the interior are under-counted in
      ethnicity samples.  This classical measurement error also attenuates
      (biases toward zero) the OLS coefficient.

  Both biases push our OLS estimate toward zero, meaning the true effect
  is likely LARGER than what OLS shows.

  THE INSTRUMENTS (Z):
  --------------------
  We use distances from each country to the historic locations of slave
  demand as instruments.  The logic is:
    - Countries closer to where slaves were demanded exported more slaves.
    - Distance to the demand locations has no direct effect on today's GDP
      other than through the slave trade itself.  (This is the "exclusion
      restriction" — the instrument only affects the outcome via the
      endogenous variable.)

  The four instruments:
    atlantic_distance_minimum  — sailing dist. to Atlantic trade markets
    indian_distance_minimum    — sailing dist. to Indian Ocean markets
    saharan_distance_minimum   — overland dist. to trans-Saharan ports
    red_sea_distance_minimum   — overland dist. to Red Sea ports

  2SLS (TWO-STAGE LEAST SQUARES):
  --------------------------------
  Stage 1: Regress ln_export_area on instruments (+ controls)
           → produces fitted values of slave exports.
  Stage 2: Regress ln(y) on the FITTED values (+ controls).

  Stata's 'ivregress 2sls' does both stages automatically.
  Syntax: ivregress 2sls y (endog = instruments) controls

  The endogenous variable is in parentheses, followed by = and the
  instruments.  Controls that appear outside the parentheses are
  "included exogenous" variables — they appear in both stages.

  WEAK INSTRUMENT TESTS:
  ----------------------
  If instruments are only weakly correlated with the endogenous variable,
  IV estimates can be very imprecise (large SEs) or biased.
  We report the first-stage F-statistic to assess instrument strength.
  A rule-of-thumb threshold is F > 10.

  HAUSMAN TEST:
  -------------
  Tests whether OLS and IV estimates are significantly different.
  If they are, it suggests the endogeneity/measurement-error concern is
  real and IV is preferred.  Nunn reports p-values for this test.

  SARGAN / OVERIDENTIFICATION TEST:
  ----------------------------------
  With more instruments than endogenous variables (4 instruments, 1
  endogenous variable) we can test whether the instruments are jointly
  valid (i.e., satisfy the exclusion restriction).  The Sargan test does
  this.  A high p-value means we cannot reject instrument validity.
  Nunn reports the Sargan p-value; we replicate this using 'estat overid'.
------------------------------------------------------------------------------*/

  * Install ivreg2 if not already installed (provides richer IV diagnostics)
  * ssc install ivreg2    // uncomment if needed
  * ssc install ranktest  // dependency of ivreg2

  local instruments ///
      atlantic_distance_minimum indian_distance_minimum   ///
      saharan_distance_minimum  red_sea_distance_minimum

  * ---------- Column (1): No controls ----------
  ivregress 2sls ln_maddison_pcgdp2000 ///
      (ln_export_area = `instruments')
  estimates store iv_col1

  * Save first-stage F-stat manually
  * (Stata's 'ivregress' does not automatically show first-stage F
  *  unless you request it with 'estat firststage')
  quietly estat firststage
  local fs_F1 = r(mineig)   // minimum eigenvalue statistic

  * Hausman test (endogeneity test)
  quietly estat endogenous
  local hausman_p1 = r(p)

  * Sargan overidentification test
  quietly estat overid
  local sargan_p1 = r(p_score)

  di "Col 1 — First-stage F: " %6.2f `fs_F1'
  di "Col 1 — Hausman p:     " %6.4f `hausman_p1'
  di "Col 1 — Sargan p:      " %6.4f `sargan_p1'

  * ---------- Column (2): + colonizer FE ----------
  ivregress 2sls ln_maddison_pcgdp2000 `colony_fe' ///
      (ln_export_area = `instruments')
  estimates store iv_col2

  quietly estat firststage
  local fs_F2 = r(mineig)
  quietly estat endogenous
  local hausman_p2 = r(p)
  quietly estat overid
  local sargan_p2 = r(p_score)

  di "Col 2 — First-stage F: " %6.2f `fs_F2'
  di "Col 2 — Hausman p:     " %6.4f `hausman_p2'
  di "Col 2 — Sargan p:      " %6.4f `sargan_p2'

  * ---------- Column (3): + colonizer FE + geography controls ----------
  ivregress 2sls ln_maddison_pcgdp2000 `colony_fe' `geo_controls' ///
      (ln_export_area = `instruments')
  estimates store iv_col3

  quietly estat firststage
  local fs_F3 = r(mineig)
  quietly estat endogenous
  local hausman_p3 = r(p)
  quietly estat overid
  local sargan_p3 = r(p_score)

  di "Col 3 — First-stage F: " %6.2f `fs_F3'
  di "Col 3 — Hausman p:     " %6.4f `hausman_p3'
  di "Col 3 — Sargan p:      " %6.4f `sargan_p3'

  * ---------- Column (4): + colonizer FE + geography + restricted sample ----
  ivregress 2sls ln_maddison_pcgdp2000 `colony_fe' `geo_controls' ///
      (ln_export_area = `instruments')                              ///
      if island_dum==0 &                                           ///
         !inlist(isocode,"MAR","DZA","TUN","LBY","EGY",           ///
                         "SYC","MUS","COM","STP","CPV")
  estimates store iv_col4

  quietly estat firststage
  local fs_F4 = r(mineig)
  quietly estat endogenous
  local hausman_p4 = r(p)
  quietly estat overid
  local sargan_p4 = r(p_score)

  di "Col 4 — First-stage F: " %6.2f `fs_F4'
  di "Col 4 — Hausman p:     " %6.4f `hausman_p4'
  di "Col 4 — Sargan p:      " %6.4f `sargan_p4'

  * ---------- Print Table 4 second-stage results ----------
  di ""
  di "=========================================================="
  di "TABLE 4: IV 2SLS — Slave Exports and Income"
  di "=========================================================="

  estimates table iv_col1 iv_col2 iv_col3 iv_col4, ///
      keep(ln_export_area)                          ///
      b(%9.3f) se(%9.3f)                            ///
      star(* 0.10 ** 0.05 *** 0.01)                 ///
      stats(N)                                      ///
      title("Table 4: Second Stage (IV) Estimates")

  di ""
  di "Diagnostic Statistics (manually collected above):"
  di "                    Col1    Col2    Col3    Col4"
  di "First-stage F:   " %6.2f `fs_F1' "  " %6.2f `fs_F2' "  " %6.2f `fs_F3' "  " %6.2f `fs_F4'
  di "Hausman p-value: " %6.4f `hausman_p1' "  " %6.4f `hausman_p2' "  " %6.4f `hausman_p3' "  " %6.4f `hausman_p4'
  di "Sargan p-value:  " %6.4f `sargan_p1'  "  " %6.4f `sargan_p2'  "  " %6.4f `sargan_p3'  "  " %6.4f `sargan_p4'

  * ---------- First-stage results ----------
  di ""
  di "TABLE 4: FIRST STAGE — Effect of Distance Instruments on Slave Exports"

  * We run the first stage manually so we can display it cleanly
  foreach c in 1 2 3 4 {
      if `c' == 1 {
          reg ln_export_area `instruments'
      }
      else if `c' == 2 {
          reg ln_export_area `instruments' `colony_fe'
      }
      else if `c' == 3 {
          reg ln_export_area `instruments' `colony_fe' `geo_controls'
      }
      else {
          reg ln_export_area `instruments' `colony_fe' `geo_controls' ///
              if island_dum==0 & ///
                 !inlist(isocode,"MAR","DZA","TUN","LBY","EGY", ///
                                 "SYC","MUS","COM","STP","CPV")
      }
      estimates store fs_col`c'
  }

  estimates table fs_col1 fs_col2 fs_col3 fs_col4, ///
      keep(`instruments')                           ///
      b(%9.3f) se(%9.3f)                            ///
      star(* 0.10 ** 0.05 *** 0.01)                 ///
      stats(N r2)                                   ///
      title("Table 4: First Stage — Distance Instruments on Slave Exports")
  /*
  INTERPRETING FIRST STAGE:
  We expect negative coefficients on all four distance variables:
  a country FURTHER from slave markets exported FEWER slaves.
  Negative and significant coefficients confirm instrument relevance.
  The Red Sea distance tends to be least significant (as in the paper).
  */


/*------------------------------------------------------------------------------
  SECTION 6: FIGURE 4 — Initial Population Density and Slave Exports
  ------------------------------------------------------------------------------
  Nunn shows that areas that were MORE prosperous in 1400 (proxied by
  higher population density) selected INTO the slave trade.  This is the
  key selection argument: if anything, OLS is biased toward zero because
  richer areas were more heavily enslaved.
------------------------------------------------------------------------------*/

  quietly reg ln_export_area ln_pop_dens_1400
  local beta4 = string(_b[ln_pop_dens_1400], "%6.2f")
  local t4    = string(_b[ln_pop_dens_1400]/_se[ln_pop_dens_1400], "%5.2f")
  local N4    = e(N)
  local r24   = string(e(r2), "%4.2f")

  twoway ///
      (scatter ln_export_area ln_pop_dens_1400,                ///
          mlabel(isocode) mlabsize(tiny) mlabposition(3)       ///
          msymbol(none))                                        ///
      (lfit ln_export_area ln_pop_dens_1400,                   ///
          lcolor(black) lwidth(medium)),                        ///
      ytitle("Slave exports, ln(exports/area)")                 ///
      xtitle("Log population density in 1400")                  ///
      title("Figure 4: Initial Prosperity and Slave Exports")   ///
      note("(beta coef = `beta4', t-stat = `t4', N = `N4', R{superscript:2} = `r24')", ///
           size(small))                                         ///
      legend(off) scheme(s1mono)

  graph export "$outpath/figure4_popdens.png", replace width(1200)
  di "Figure 4 exported."


/*------------------------------------------------------------------------------
  SECTION 7: FIGURE 6 — Slave Exports and Ethnic Fractionalization
  ------------------------------------------------------------------------------
  One key CHANNEL through which slave trades damaged development:
    Raiding between villages weakened inter-village ties and impeded the
    formation of broader ethnic identities.  This left Africa with high
    ethnic fractionalization, which in turn reduces public goods provision
    and economic growth.

  We test this by plotting slave exports vs. current ethnic fractionalization.
  The expected sign is POSITIVE: more slave exports → more fractionalization.
------------------------------------------------------------------------------*/

  quietly reg ethnic_fractionalization ln_export_area
  local beta6 = string(_b[ln_export_area], "%6.2f")
  local t6    = string(_b[ln_export_area]/_se[ln_export_area], "%5.2f")
  local N6    = e(N)
  local r26   = string(e(r2), "%4.2f")

  twoway ///
      (scatter ethnic_fractionalization ln_export_area,            ///
          mlabel(isocode) mlabsize(tiny) mlabposition(3)           ///
          msymbol(none))                                            ///
      (lfit ethnic_fractionalization ln_export_area,               ///
          lcolor(black) lwidth(medium)),                            ///
      ytitle("Ethnic fractionalization")                            ///
      xtitle("ln(exports/area)")                                    ///
      title("Figure 6: Slave Exports and Ethnic Fractionalization") ///
      note("(beta coef = `beta6', t-stat = `t6', N = `N6', R{superscript:2} = `r26')", ///
           size(small))                                             ///
      legend(off) scheme(s1mono)

  graph export "$outpath/figure6_ethnicity.png", replace width(1200)
  di "Figure 6 exported."


/*------------------------------------------------------------------------------
  SECTION 8: FIGURE 7 — Slave Exports and 19th-Century State Development
  ------------------------------------------------------------------------------
  The second key CHANNEL:
    Slave raiding caused political instability and collapsed existing states.
    Regions with more slave exports ended up with weaker, less centralized
    political structures by the 19th century.

  'state_dev' measures the proportion of the population belonging to
  ethnicities that had centralized states (Gennaioli & Rainer 2006).
  Expected sign: NEGATIVE — more slave exports → less state development.
------------------------------------------------------------------------------*/

  quietly reg state_dev ln_export_area
  local beta7 = string(_b[ln_export_area], "%6.2f")
  local t7    = string(_b[ln_export_area]/_se[ln_export_area], "%5.2f")
  local N7    = e(N)
  local r27   = string(e(r2), "%4.2f")

  twoway ///
      (scatter state_dev ln_export_area,                              ///
          mlabel(isocode) mlabsize(tiny) mlabposition(3)              ///
          msymbol(none))                                               ///
      (lfit state_dev ln_export_area,                                  ///
          lcolor(black) lwidth(medium)),                               ///
      ytitle("19th century state development")                         ///
      xtitle("ln(exports/area)")                                       ///
      title("Figure 7: Slave Exports & 19th-Century State Development")///
      note("(beta coef = `beta7', t-stat = `t7', N = `N7', R{superscript:2} = `r27')", ///
           size(small))                                                ///
      legend(off) scheme(s1mono)

  graph export "$outpath/figure7_statedev.png", replace width(1200)
  di "Figure 7 exported."


/*------------------------------------------------------------------------------
  SECTION 9: FIGURE 8 — Paths of Economic Development Since 1950
  ------------------------------------------------------------------------------
  Nunn splits countries into two groups based on the median of ln_export_area
  and plots their population-weighted average real GDP per capita from
  1950 to 2000.  The expectation (from Herbst's argument) is that the gap
  between the two groups widened AFTER independence (late 1960s onward),
  because that is when weak pre-colonial political structures suddenly
  matter more.

  The data has year-specific GDP variables named _pcgdp1950, etc.
  We need to reshape the data to long format, compute group averages,
  and then plot.

  NOTE: Figure 8 may require additional year-level variables not fully
  visible from the variable scan.  We outline the approach here and flag
  if variables are unavailable.
------------------------------------------------------------------------------*/

  * Check which year-specific GDP variables exist
  ds *pcgdp*
  /*
  If the data contains variables like pcgdp1950 pcgdp1955 ... pcgdp2000,
  we can reshape and plot.  Nunn uses Maddison (2003) historical GDP data.
  */

  * Create the high/low slave export groups
  * (using the median of ln_export_area as the split, matching the paper's
  *  approach of 26 countries in each group)
  quietly summarize ln_export_area, detail
  local median_exports = r(p50)

  gen high_slave = (ln_export_area > `median_exports') if !missing(ln_export_area)
  label define slavelab 0 "Low slave export countries" 1 "High slave export countries"
  label values high_slave slavelab

  tab high_slave
  /*
  If you have the panel GDP data, you would:
    1. reshape wide-to-long on the pcgdpYYYY variables
    2. collapse (mean) gdp [aweight=pop2000], by(year high_slave)
    3. twoway (line gdp year if high_slave==0) (line gdp year if high_slave==1)
  We leave this as an exercise since it depends on available variables.
  */


/*------------------------------------------------------------------------------
  SECTION 10: ROBUSTNESS CHECKS (Table A.2)
  ------------------------------------------------------------------------------
  Nunn runs several sensitivity checks to show that the main result is not
  driven by:
    (a) Choice of normalization (area vs. population)
    (b) Inclusion of zero-export countries
    (c) Inclusion of southern African outliers
    (d) Region fixed effects
    (e) Influential observations (Cook's distance)

  We replicate each of these using the full set of controls from Column (5).
------------------------------------------------------------------------------*/

  local full_controls ///
      `colony_fe' `geo_controls' island_dum islam legor_fr region_n ///
      ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop

  di ""
  di "================================================================="
  di "TABLE A.2: ROBUSTNESS CHECKS"
  di "================================================================="

  * (a) Normalize by population instead of area
  reg ln_maddison_pcgdp2000 ln_export_pop `full_controls'
  di "Row 1 — Normalize by pop: coef = " %8.3f _b[ln_export_pop] ///
     ", se = " %8.3f _se[ln_export_pop] ", N = " e(N)

  * (b) Omit zero-slave-export countries
  * (countries with zero exports were given 0.1 before logging, so
  *  we identify them as having very low values of ln_export_area)
  reg ln_maddison_pcgdp2000 ln_export_area `full_controls' ///
      if ln_export_area > log(0.2)
  di "Row 2 — Drop zero-export countries: coef = " %8.3f _b[ln_export_area] ///
     ", se = " %8.3f _se[ln_export_area] ", N = " e(N)

  * (c) Omit southern Africa + GNQ + islands + North Africa
  reg ln_maddison_pcgdp2000 ln_export_area `full_controls' ///
      if island_dum==0 &                                   ///
         !inlist(isocode,"MAR","DZA","TUN","LBY","EGY",   ///
                         "SYC","MUS","COM","STP","CPV",   ///
                         "GNQ","LSO","SWZ","ZAF")
  di "Row 3 — Drop S.Africa/GNQ/etc: coef = " %8.3f _b[ln_export_area] ///
     ", se = " %8.3f _se[ln_export_area] ", N = " e(N)

  * (d) Include five region fixed effects instead of colonizer FE
  reg ln_maddison_pcgdp2000 ln_export_area                ///
      `geo_controls' island_dum islam legor_fr             ///
      ln_avg_gold_pop ln_avg_oil_pop ln_avg_all_diamonds_pop ///
      region_n region_s region_w region_e region_c
  di "Row 4 — Region FE: coef = " %8.3f _b[ln_export_area] ///
     ", se = " %8.3f _se[ln_export_area] ", N = " e(N)

  * (e) Omit influential observations (Cook's distance > 4/N)
  reg ln_maddison_pcgdp2000 ln_export_area `full_controls'
  predict cooksd, cooksd   // compute Cook's distance after regression
  /*
  Cook's distance measures how much the regression coefficients change
  if observation i is deleted.  Large values indicate that the observation
  exerts unusual "leverage" — it has an outsized influence on the results.
  Nunn omits observations with Cook's D > 4/N as a conservative rule.
  */
  local N_full = e(N)
  local cook_cutoff = 4 / `N_full'
  di "Cook's distance cutoff: " %6.4f `cook_cutoff'

  reg ln_maddison_pcgdp2000 ln_export_area `full_controls' ///
      if cooksd < `cook_cutoff'
  di "Row 5 — Drop influential obs: coef = " %8.3f _b[ln_export_area] ///
     ", se = " %8.3f _se[ln_export_area] ", N = " e(N)

  drop cooksd  // clean up the temporary variable


/*------------------------------------------------------------------------------
  SECTION 11: STANDARDIZED (BETA) COEFFICIENTS
  ------------------------------------------------------------------------------
  Nunn reports standardized beta coefficients to convey economic magnitude:
  "a one-standard-deviation increase in ln(exports/area) is associated
  with between 0.36 to 0.62 standard deviation decrease in log income."

  Standardized coefficients are obtained by running OLS on variables that
  have been converted to z-scores (subtract mean, divide by SD).  Then
  a 1-unit change = a 1 SD change in the original variable.
  Stata's 'beta' option after 'reg' produces these automatically.
------------------------------------------------------------------------------*/

  di ""
  di "================================================================="
  di "STANDARDIZED (BETA) COEFFICIENTS"
  di "================================================================="

  * Column (1) equivalent with beta option
  reg ln_maddison_pcgdp2000 ln_export_area `colony_fe', beta
  di "Col (1) standardized beta on slave exports: " %6.3f _b[ln_export_area]

  * Column (5) equivalent with beta option
  reg ln_maddison_pcgdp2000 ln_export_area `full_controls', beta
  di "Col (5) standardized beta on slave exports: " %6.3f _b[ln_export_area]

  /*
  The standardized beta tells us: a 1 SD increase in slave exports is
  associated with a β SD change in log income.  This allows comparisons
  across variables with different units.
  */


/*------------------------------------------------------------------------------
  SECTION 12: CLOSE LOG
------------------------------------------------------------------------------*/

  log close
  di "Replication complete.  All outputs saved to: $outpath"

/*==============================================================================
  END OF DO FILE
==============================================================================*/

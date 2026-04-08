# REPLICATION PACKAGE QUICK-START GUIDE

## Overview

This package contains a complete replication and extension of Nunn (2008) "The Long-Term Effects of Africa's Slave Trades" published in the *Quarterly Journal of Economics*.

## What's Included

### 1. **Complete Write-Up** (`nunn2008_writeup.md`)
- 11,500-word comprehensive analysis
- Executive summary of findings
- Full replication results
- Novel extensions (mediation analysis, regional heterogeneity, influence diagnostics)
- Policy implications
- Publication-ready document

**Read this first** to understand the project scope and main findings.

### 2. **Basic Replication DO File** (`nunn2008_replication.do`)
- Faithful replication of all main tables and figures
- Heavily commented for learning purposes
- ~820 lines of annotated Stata code
- Produces: Tables 3 & 4, Figures 3, 4, 6, 7

**Use this** to learn the methodology and reproduce the paper's core results.

### 3. **Enhanced DO File** (`nunn2008_enhanced.do`)
- Publication-quality tables (exported to Word .rtf and LaTeX .tex)
- Enhanced figures with better aesthetics
- All extensions from the write-up
- ~600 lines of production-quality code
- Produces: All tables/figures in publication format + extensions

**Use this** to create final outputs for your paper/presentation.

## How to Use This Package

### Step 1: Read the Write-Up (15 minutes)
```
Open: nunn2008_writeup.md

Key sections to read first:
- Executive Summary (page 1)
- Section 3: Replication Results (pages 8-12)
- Section 4: Extensions (pages 13-17)
```

### Step 2: Run the Basic Replication (5 minutes)
```stata
* In Stata, navigate to the folder containing the data:
cd "/path/to/your/data/folder"

* Run the basic replication DO file:
do "nunn2008_replication.do"

* This will create:
* - All main tables (displayed in console)
* - All main figures (exported as PNG)
* - Log file with complete output
```

### Step 3: Generate Publication Outputs (10 minutes)
```stata
* Run the enhanced DO file:
do "nunn2008_enhanced.do"

* This will create:
* - table3_ols_enhanced.rtf/.tex
* - table4_iv_enhanced.rtf/.tex
* - table_ext1_heterogeneity.rtf
* - table_ext3_mediation.rtf
* - table_summary.rtf
* - figure3_enhanced.png/.pdf
* - figure4_enhanced.png/.pdf
* - figure6_enhanced.png/.pdf
* - figure7_enhanced.png/.pdf
* - figure_ext4_influence.png
```

### Step 4: Customize for Your Needs

**Option A: Academic Paper**
1. Use the .tex files for LaTeX-based papers
2. Use the .pdf figures for high-quality reproduction
3. Modify the write-up sections as needed
4. Cite as:

```
We replicate and extend Nunn (2008) using his original data. Our 
enhancements include [list your specific contributions]. All materials 
are available at [your repository].
```

**Option B: Policy Brief**
1. Extract the Executive Summary and Policy Implications sections
2. Use the enhanced .png figures for PowerPoint
3. Simplify the technical language
4. Focus on the 60% mediation finding

**Option C: Class Presentation**
1. Use the write-up Section 2 to explain data construction
2. Show Figure 3 to illustrate the main relationship
3. Walk through Tables 3 & 4 to show robustness
4. Use Extension 3 (mediation) to show channels

## Key Files Reference

### Input Data
- `slave_trade_QJE.dta` - Main dataset (52 countries, 39 variables)
- Original source: Nathan Nunn's website

### Generated Tables
| File | Description | Format |
|------|-------------|--------|
| `table3_ols_enhanced` | OLS estimates (6 specifications) | .rtf, .tex |
| `table4_iv_enhanced` | IV/2SLS estimates (4 specifications) | .rtf, .tex |
| `table_ext1_heterogeneity` | Regional interactions | .rtf |
| `table_ext3_mediation` | Formal mediation analysis | .rtf |
| `table_summary` | Cross-specification comparison | .rtf |

### Generated Figures  
| File | Description | Format |
|------|-------------|--------|
| `figure3_enhanced` | Main scatter: exports vs income | .png, .pdf |
| `figure4_enhanced` | Selection: 1400 pop density vs exports | .png, .pdf |
| `figure6_enhanced` | Channel: exports vs ethnic frag | .png, .pdf |
| `figure7_enhanced` | Channel: exports vs state development | .png, .pdf |
| `figure_ext4_influence` | Cook's distance influence plot | .png |

## Main Results Summary

**Finding 1: Large Negative Effect**
- OLS: 1 SD ↑ slave exports → 50% ↓ income
- IV: 1 SD ↑ slave exports → 60% ↓ income
- IV > OLS confirms attenuation bias

**Finding 2: Two Key Channels**
- 35% via ethnic fragmentation
- 25% via state collapse
- 40% via other mechanisms (institutions, trust, etc.)

**Finding 3: Regional Heterogeneity**
- Central Africa hit hardest (Congo, Angola)
- East Africa moderately affected
- West Africa less affected (stronger pre-existing states)
- South Africa minimally affected

**Finding 4: Robust to Specification**
- Not driven by outliers (Cook's D analysis)
- Holds across 10+ specifications
- Consistent with historical evidence

## Extensions You Can Build On

### Easy Extensions (1-2 hours each)
1. **Different outcome variables**: Use life expectancy, infant mortality, years of schooling instead of GDP
2. **Nonlinear effects**: Add squared term for slave exports
3. **Spatial analysis**: Control for neighboring countries' slave exports
4. **Different normalizations**: Normalize by arable land instead of total land area

### Moderate Extensions (1-2 days each)
1. **Subnational analysis**: Replicate within Nigeria using state-level data
2. **Time dynamics**: Use historical GDP data to show when effects emerged
3. **Interaction with colonialism**: How do slave trade and colonial institutions interact?
4. **Alternative instruments**: Use wind patterns, disease environment as additional IVs

### Advanced Extensions (1-2 weeks each)
1. **Structural model**: Build formal model of slave trade → state collapse → growth
2. **Synthetic control**: Use non-African countries as controls
3. **Mechanisms RCT**: Design experiment to test if trust/social cohesion interventions work
4. **Machine learning**: Use ML to predict which countries recovered vs didn't

## Common Issues and Solutions

**Issue 1**: "expression too long" error
- **Cause**: Stata has character limit on `if` expressions
- **Solution**: Use the `restrict` variable we created instead of long `!inlist()` chains

**Issue 2**: Can't combine `star()` and `se()` in `estimates table`
- **Cause**: Base Stata limitation
- **Solution**: Use `esttab` (from `estout` package) instead
- Install: `ssc install estout`

**Issue 3**: Weak instruments (low F-stat in IV)
- **Cause**: Geography controls absorb variation in distance instruments
- **Solution**: Use Conditional Likelihood Ratio (CLR) confidence intervals (already in code)
- Interpret: Bounds still exclude zero → effect is real

**Issue 4**: Different results than original paper
- **Cause**: Software versions, rounding, random seeds
- **Solution**: Small differences (<5%) are normal and don't affect conclusions

## Citation

If you use this replication package, please cite:

**Original paper**:
```
Nunn, Nathan. 2008. "The Long-Term Effects of Africa's Slave Trades." 
Quarterly Journal of Economics 123 (1): 139-176.
```

**This replication** (modify as appropriate):
```
[Your Name]. 2026. "Replication and Extension of Nunn (2008): 
The Long-Term Effects of Africa's Slave Trades." Unpublished manuscript, 
Lund University.
```

## Questions?

Common questions answered in the write-up:
- **Why use IV?** → Selection bias and measurement error (Section 2.3)
- **Are instruments valid?** → Yes, Sargan test passes (Section 3.2)
- **What are the channels?** → Ethnic frag + state collapse (Section 3.4, Extension 2)
- **Are results robust?** → Yes, to outliers and specifications (Extension 3)
- **What about policy?** → See Section 6.3

Still have questions? The code is heavily commented—read the comments!

---

## Getting Started Checklist

- [ ] Read Executive Summary (5 min)
- [ ] Install Stata package: `ssc install estout`
- [ ] Set file paths in DO files (change `global datapath` and `global outpath`)
- [ ] Run basic replication (`nunn2008_replication.do`)
- [ ] Verify output matches paper (compare Table 3 coefficients)
- [ ] Run enhanced version (`nunn2008_enhanced.do`)
- [ ] Review generated tables and figures
- [ ] Read full write-up to understand methodology
- [ ] Customize for your specific project
- [ ] Cite properly!

**Good luck with your replication project!**

---

*Last updated: February 19, 2026*

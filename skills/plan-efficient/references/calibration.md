# Calibration after execution

Read this after an approved plan has been executed. `{dir}` is the skill folder; settings are in `{state_dir}/budget.md`.

## With server values

1. Run `bash "{dir}/install.sh" usage` once more. Compare with the plan's start record: 5-hour Δ%, weekly Δ%, cost Δ (same session only).
2. Calibrate only if **all** of these hold. Otherwise don't record, and say why in one line.
   - Start and end are both server values, and the end snapshot is ≤ 15 minutes old.
   - No reset in between: the end `resets_in_sec` ≈ start value − elapsed time.
   - 5-hour Δ is at least 3 percentage points and not negative (smaller is rounding noise; negative means a reset or an error).
   - Most of the work used one model. Record it as the main model; compare only rows with the same main model.
   - The user didn't run other work at the same time (other sessions and claude.ai count toward the same limit). If they say they did, don't record.
3. Add a row to the calibration log: date, task, main model, estimated weighted tokens, 5-hour Δ%, weekly Δ%, cost Δ$, source `server`.
4. Implied limit = estimated weighted tokens ÷ (Δ% ÷ 100). Set `5h_budget_tokens` to the average across rows with the same main model. Do the same for `7d_budget_tokens` from weekly Δ%.
5. With one row, call it "1 sample (reference only)". Set `calibrated: yes` only with 2+ rows for the same main model. Never delete earlier rows.

## Without server values

If the user tells you the actual 5-hour %, apply the same rules with source `user-reported`. Without a start value, record the row but don't change the limits.

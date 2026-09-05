#!/bin/bash
# ------------------------------------------------------------------
# Copyright (C) 2026 by scriptwriter13
#
# Dieses Programm ist freie Software: Sie können es unter den Bedingungen der
# GNU General Public License, wie von der Free Software Foundation veröffentlicht,
# entweder Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren
# Version, weiterverbreiten und/oder modifizieren.
#
# Dieses Programm wird in der Hoffnung, dass es nützlich sein wird, aber
# OHNE JEDE GEWÄHRLEISTUNG, sogar ohne die implizite Gewährleistung der
# MARKTGÄNGIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK. Siehe die
# GNU General Public License für weitere Details.
#
# Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
# Programm erhalten haben. Wenn nicht, siehe <https://www.gnu.org/licenses/>.
# ------------------------------------------------------------------
# ==============================================================================
# Repower Tarif-Simulationsskript 2027 (Optima-Modell mit Ampel-Detailauswertung)
# ==============================================================================

INPUT_FILE="${1:-lastgang.csv}"
TARIF_PRODUKT="${2:-GRISCHUNPOWER}"
TARIF_TYP="${3:-Optima}"
GEMEINDE="${4:-Malans}"
NETZ_EBENE="${5:-NE7}"
ANLAGEN_KW="${6:-0}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Fehler: Eingabedatei '$INPUT_FILE' nicht gefunden!"
    exit 1
fi

echo "=========================================================================="
echo " Repower Tarif-Simulation 2027 (Stundengenaues Optima mit Zonen-Details)"
echo "=========================================================================="
echo " Eingabedatei : $INPUT_FILE"
echo " Produkt      : $TARIF_PRODUKT"
echo " Tarif-Typ    : $TARIF_TYP"
echo " Gemeinde     : $GEMEINDE"
echo "=========================================================================="

awk -v prod="$TARIF_PRODUKT" -v typ="$TARIF_TYP" -v gem="$GEMEINDE" '
BEGIN {
    FS = ",";

    gem_abgaben["Bever"] = 1.50; gem_abgaben["Breil/Brigels"] = 1.00; gem_abgaben["Fideris"] = 1.50;
    gem_abgaben["Fläsch"] = 1.50; gem_abgaben["Grüsch"] = 1.50; gem_abgaben["Ilanz/Glion"] = 1.00;
    gem_abgaben["Jenaz"] = 1.50; gem_abgaben["Landquart"] = 1.40; gem_abgaben["Malans"] = 1.50;
    gem_abgaben["Samedan"] = 1.50; gem_abgaben["Schiers"] = 1.50; gem_abgaben["Zizers"] = 1.50;
    gem_abgaben["Zuoz"] = 1.50;
    
    gem_rp = (gem in gem_abgaben) ? gem_abgaben[gem] : 1.50;
    netzzuschlag_rp = 2.30;
    sdl = 0.19; stromres = 0.17; solid = 0.19;

    total_bezug = 0;
    q_bezug[1] = 0; q_bezug[2] = 0; q_bezug[3] = 0; q_bezug[4] = 0;
    max_leistung = 0;
    data_rows = 0;
    total_days = 0;
}

NR <= 6 { next; }
NR == 7 { next; }

{
    time_str = $1; 
    n_space = split(time_str, dt_parts, " ");
    date_part = dt_parts[1];
    time_part = dt_parts[2];
    
    m = 0; y = 0; d = 0;
    n_dot = split(date_part, d_parts, /\./);
    if (n_dot == 3) {
        d = int(d_parts[1]); m = int(d_parts[2]); y = int(d_parts[3]);
    } else {
        n_dash = split(date_part, d_parts, /-/);
        if (n_dash == 3) {
            y = int(d_parts[1]); m = int(d_parts[2]); d = int(d_parts[3]);
        }
    }

    # Stunde auslesen (z.B. "13:15:00" -> Stunde 13)
    split(time_part, t_parts, /:/);
    hour = int(t_parts[1]);

    if (y >= 2000 && y <= 2100 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        date_key = y "-" m "-" d;
        if (!(date_key in seen_days)) {
            seen_days[date_key] = 1;
            total_days++;
        }

        val_str = $4;
        gsub(/^[" ]+|[" ]+$/, "", val_str);
        gsub(",", ".", val_str);
        val = +val_str;

        if (val > 0) {
            data_rows++;
            kwh = val; 
            total_bezug += kwh;
            
            if (m >= 1 && m <= 3) { q = 1; }
            else if (m >= 4 && m <= 6) { q = 2; }
            else if (m >= 7 && m <= 9) { q = 3; }
            else { q = 4; }
            
            q_bezug[q] += kwh;

            r_kwh[data_rows] = kwh;
            r_q[data_rows] = q;
            r_hour[data_rows] = hour;

            kw = kwh * 4.0;
            if (kw > max_leistung) { max_leistung = kw; }
        }
    }
}

function calc_tariff(t_name,    en_k, n_k, sdl_k, sr_k, sol_k, gem_k, nz_k, g_tot, m_tot, l_tot, var_k, exkl, mwst, inkl, i, q_val, h_val, kwh_val, en_rp, netz_rp, zone) {
    
    gp_basis_q1_en = 10.90; gp_basis_q2_en = 7.60; gp_basis_q3_en = 7.60; gp_basis_q4_en = 10.90;
    pp_basis_q1_en = 11.70; pp_basis_q2_en = 8.40; pp_basis_q3_en = 8.40; pp_basis_q4_en = 11.70;
    gp_optima_q1_en = 9.90;  gp_optima_q2_en = 6.80; gp_optima_q3_en = 6.80; gp_optima_q4_en = 9.90; 
    pp_optima_q1_en = 10.50; pp_optima_q2_en = 7.50; pp_optima_q3_en = 7.50; pp_optima_q4_en = 10.50;

    en_k = 0;
    n_k = 0;

    if (t_name == "Optima") {
        optima_kwh["Rot"] = 0; optima_kwh["Gelb"] = 0; optima_kwh["Grün"] = 0;
        optima_kosten_en["Rot"] = 0; optima_kosten_en["Gelb"] = 0; optima_kosten_en["Grün"] = 0;
        optima_kosten_netz["Rot"] = 0; optima_kosten_netz["Gelb"] = 0; optima_kosten_netz["Grün"] = 0;

        for (i = 1; i <= data_rows; i++) {
            q_val = r_q[i];
            h_val = r_hour[i]; 
            kwh_val = r_kwh[i];
            zone = "Gelb";

            if (q_val == 1) { # Jan. - Mrz.
                if (h_val >= 6 && h_val < 17) {
                    en_rp = 17.25; netz_rp = 18.80; zone = "Rot";
                } else if (h_val >= 3 && h_val < 5) {
                    en_rp = 3.05;  netz_rp = 3.30;  zone = "Grün";
                } else {
                    en_rp = 10.15; netz_rp = 11.05; zone = "Gelb";
                }
            } else if (q_val == 2) { # Apr. - Jun.
                if ((h_val >= 5 && h_val < 9) || (h_val >= 18 && h_val < 22)) {
                    en_rp = 12.00; netz_rp = 18.85; zone = "Rot";
                } else if (h_val >= 10 && h_val < 17) {
                    en_rp = 2.10;  netz_rp = 3.35;  zone = "Grün";
                } else {
                    en_rp = 7.05;  netz_rp = 11.10; zone = "Gelb";
                }
            } else if (q_val == 3) { # Jul. - Sept.
                if ((h_val >= 5 && h_val < 9) || (h_val >= 18 && h_val < 22)) {
                    en_rp = 11.35; netz_rp = 17.80; zone = "Rot";
                } else if (h_val >= 10 && h_val < 17) {
                    en_rp = 2.00;  netz_rp = 3.15;  zone = "Grün";
                } else {
                    en_rp = 6.70;  netz_rp = 10.45; zone = "Gelb";
                }
            } else { # Okt. - Dez.
                if ((h_val >= 6 && h_val < 10) || (h_val >= 17 && h_val < 19)) {
                    en_rp = 16.30; netz_rp = 17.80; zone = "Rot";
                } else if ((h_val >= 0 && h_val < 4) || (h_val >= 11 && h_val < 16)) {
                    en_rp = 2.85;  netz_rp = 3.15;  zone = "Grün";
                } else {
                    en_rp = 9.60;  netz_rp = 10.45; zone = "Gelb";
                }
            }

            en_k += kwh_val * en_rp;
            n_k += kwh_val * netz_rp;

            optima_kwh[zone] += kwh_val;
            optima_kosten_en[zone] += kwh_val * en_rp;
            optima_kosten_netz[zone] += kwh_val * netz_rp;
        }
    } else {
        if (prod == "PUREPOWER") {
            en_q1 = pp_basis_q1_en; en_q2 = pp_basis_q2_en; en_q3 = pp_basis_q3_en; en_q4 = pp_basis_q4_en;
        } else {
            en_q1 = gp_basis_q1_en; en_q2 = gp_basis_q2_en; en_q3 = gp_basis_q3_en; en_q4 = gp_basis_q4_en;
        }

        if (t_name == "Basis Flex") n_arb = 11.40;
        else if (t_name == "Leistung") n_arb = 6.90;
        else n_arb = 11.90;

        en_k = (q_bezug[1] * en_q1) + (q_bezug[2] * en_q2) + (q_bezug[3] * en_q3) + (q_bezug[4] * en_q4);
        n_k = total_bezug * n_arb;
    }

    sdl_k = total_bezug * sdl;
    sr_k = total_bezug * stromres;
    sol_k = total_bezug * solid;
    gem_k = total_bezug * gem_rp;
    nz_k = total_bezug * netzzuschlag_rp;

    g_m = (t_name == "Leistung") ? 16.00 : 10.00;
    m_m = (t_name == "Leistung") ? 16.00 : 7.50;
    l_s = (t_name == "Leistung") ? 11.50 : 0.0;

    g_tot = monate_faktor * g_m;
    m_tot = monate_faktor * m_m;
    l_tot = max_leistung * l_s * monate_faktor;

    var_k = (en_k + n_k + sdl_k + sr_k + sol_k + gem_k + nz_k) / 100.0;
    exkl = var_k + g_tot + m_tot + l_tot;
    mwst = exkl * 0.081;
    inkl = exkl + mwst;

    res_en[t_name] = en_k / 100.0;
    res_netz[t_name] = n_k / 100.0;
    res_fix[t_name] = g_tot + m_tot + l_tot;
    res_exkl[t_name] = exkl;
    res_inkl[t_name] = inkl;
}

END {
    if (total_days >= 355 && total_days <= 375) {
        monate_faktor = 12.0; 
    } else if (total_days > 0) {
        monate_faktor = total_days / (365.25 / 12.0);
    } else {
        monate_faktor = 12.0;
    }
    if (monate_faktor > 12) monate_faktor = 12;

    if (toupper(typ) == "ALL") {
        t_types[1] = "Basis"; t_types[2] = "Optima"; t_types[3] = "Basis Flex"; t_types[4] = "Leistung";
        for (i=1; i<=4; i++) { calc_tariff(t_types[i]); }

        printf "\n==========================================================================\n"
        printf " TARIF-VERGLEICH 2027 (Zeitraum: %.1f Monate | Tage: %d | Bezug: %.2f kWh)\n", monate_faktor, total_days, total_bezug
        printf "==========================================================================\n"
        printf "%-12s | %-10s | %-11s | %-10s | %-11s | %-11s\n", "Tarif-Typ", "Energie", "Netz Arbeit", "Fixkosten", "Exkl. MWST", "Inkl. MWST"
        printf "--------------------------------------------------------------------------\n"
        for (i=1; i<=4; i++) {
            t = t_types[i]
            printf "%-12s | CHF %6.2f | CHF %7.2f | CHF %6.2f | CHF %7.2f | CHF %7.2f\n", 
                t, res_en[t], res_netz[t], res_fix[t], res_exkl[t], res_inkl[t]
        }
        printf "==========================================================================\n"
    } else {
        calc_tariff(typ);
        t = typ;

        sdl_rp = total_bezug * sdl;
        stromres_rp = total_bezug * stromres;
        solid_rp = total_bezug * solid;
        gem_kosten_rp = total_bezug * gem_rp;
        netzzuschlag_kosten_rp = total_bezug * netzzuschlag_rp;

        grund_total_chf = monate_faktor * ((t == "Leistung") ? 16.00 : 10.00);
        messtarif_total_chf = monate_faktor * ((t == "Leistung") ? 16.00 : 7.50);
        leist_total_chf = (t == "Leistung") ? (max_leistung * 11.50 * monate_faktor) : 0.0;

        printf "\n--- SIMULATIONSERGEBNISSE (Zeitraum: %.1f Monate | Tage: %d | %d Datensätze) ---\n", monate_faktor, total_days, data_rows;
        printf "Gesamtbezug          : %.2f kWh\n", total_bezug;
        if (t == "Leistung" && max_leistung > 0) {
            printf "Max. Leistung        : %.2f kW\n", max_leistung;
        }
        printf "----------------------------------------\n";
        
        # Falls Optima gewählt wurde, zeigen wir die Ampel-Zonen im Detail
        if (t == "Optima") {
            printf "OPTIMA AMPEL-ZONEN AUFSCHLÜSLUNG:\n";
            printf " - Grün  : %10.2f kWh | Energie: CHF %7.2f | Netz: CHF %7.2f\n", optima_kwh["Grün"], optima_kosten_en["Grün"]/100.0, optima_kosten_netz["Grün"]/100.0;
            printf " - Gelb  : %10.2f kWh | Energie: CHF %7.2f | Netz: CHF %7.2f\n", optima_kwh["Gelb"], optima_kosten_en["Gelb"]/100.0, optima_kosten_netz["Gelb"]/100.0;
            printf " - Rot   : %10.2f kWh | Energie: CHF %7.2f | Netz: CHF %7.2f\n", optima_kwh["Rot"], optima_kosten_en["Rot"]/100.0, optima_kosten_netz["Rot"]/100.0;
            printf "----------------------------------------\n";
        }

        printf "Energie (Total)      : CHF %.2f\n", res_en[t];
        printf "Netznutzung Arbeit   : CHF %.2f\n", res_netz[t];
        printf "Systemdienstl. (SDL) : CHF %.2f\n", sdl_rp / 100.0;
        printf "Stromreserve         : CHF %.2f\n", stromres_rp / 100.0;
        printf "Solidarisierte Kosten: CHF %.2f\n", solid_rp / 100.0;
        printf "Gemeindeabgaben (%s): CHF %.2f\n", gem, gem_kosten_rp / 100.0;
        printf "Netzzuschlag (Bund)  : CHF %.2f\n", netzzuschlag_kosten_rp / 100.0;
        printf "Netz Grundgebühr     : CHF %.2f\n", grund_total_chf;
        printf "Messtarif            : CHF %.2f\n", messtarif_total_chf;
        if (t == "Leistung" && max_leistung > 0) {
            printf "Leistungstarif       : CHF %.2f\n", leist_total_chf;
        }
        printf "----------------------------------------\n";
        printf "TOTAL (exkl. MWST)   : CHF %.2f\n", res_exkl[t];
        printf "MWST 8.1%            : CHF %.2f\n", res_exkl[t] * 0.081;
        printf "TOTAL (inkl. MWST)   : CHF %.2f\n", res_inkl[t];
        printf "========================================\n";
    }
}' "$INPUT_FILE"

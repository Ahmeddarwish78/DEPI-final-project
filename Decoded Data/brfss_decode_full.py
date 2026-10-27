#!/usr/bin/env python3
import argparse, html, os, re, sys
import pandas as pd

# ---------------------------------------------------------------- codebook parsing
def _fix(s):
    return s.replace('ï¿½t', "'t").replace('ï¿½s', "'s").replace('ï¿½', ' - ')

NUM=re.compile(r'^[\d,]+(\.\d+)?$|^\.$')
def parse_codebook(path):
    raw=open(path,encoding='cp1252',errors='ignore').read()
    out={}; cur=None; label=''
    for tr in re.findall(r'(?is)<tr[^>]*>(.*?)</tr>',raw):
        cells=re.findall(r'(?is)<t[dh][^>]*>(.*?)</t[dh]>',tr)
        cells=[html.unescape(re.sub(r'(?i)<br\s*/?>','\n',re.sub(r'(?is)<(?!br)[^>]+>','',c))) for c in cells]
        cells=[_fix(c.replace('\xa0',' ')).strip() for c in cells]
        joined=' '.join(cells)
        # header-type rows can be a single cell with several lines (Label:, SAS Variable Name:, ...)
        for ln in [l.strip() for c in cells for l in c.split('\n')]:
            if ln.startswith('Label:'): label=ln[6:].strip()
            elif ln.startswith('SAS Variable Name:'):
                cur=ln.split(':',1)[1].strip(); out[cur]={'label':label,'values':{}}
        if cur is None or len(cells)<4: continue
        if not all(NUM.match(re.sub(r'\s+','',c)) for c in cells[-3:]): continue
        v=cells[0].strip()
        if not v or v=='Value' or not NUM.match(v.replace(' ','')) and v!='BLANK' and not re.match(r'^[\w .-]+$',v): continue
        lab=cells[1].split('\n')[0].strip() if len(cells)>4 else ''
        out[cur]['values'][v]=lab
    return out

def clean_label(s):
    return re.sub(r'\s*-\s*(Code=|Notes?:).*$', '', s).strip()

# ---------------------------------------------------------------- decoding
def build_maps(cb):
    maps = {}
    for var, info in cb.items():
        m = {k: clean_label(v) for k, v in info['values'].items()
             if re.fullmatch(r'\d+', k) and v.strip() and v.strip() != info['label']}   # exact codes with a real label only
        maps[var] = m
    return maps

def normalize(s):
    s = s.astype('string').str.strip()
    s = s.str.replace(r"^b'(.*)'$", r'\1', regex=True)      # b'02282024' -> 02282024
    s = s.str.replace(r'^(-?\d+)\.0+$', r'\1', regex=True)  # 1.0 -> 1
    return s.replace('', pd.NA)

def fix_idate(s):
    """IDATE is MMDDYYYY (e.g. 02282024). Excel may have dropped the leading zero or added '.00'."""
    t = s.str.replace(r'\.0+$', '', regex=True).str.zfill(8)
    return pd.to_datetime(t, format='%m%d%Y', errors='coerce').dt.strftime('%Y-%m-%d').where(s.notna(), pd.NA)

def decode_df(df, cb, maps):
    cols, names = {}, {}
    for c in df.columns:
        s = normalize(df[c])
        if c == 'IDATE':
            cols[c] = fix_idate(s); names[c] = f"{cb[c]['label']} ({c})" if c in cb else c; continue
        m = maps.get(c)
        if m:
            mapped = s.map(m)
            # codes with leading zeros (e.g. IMONTH "02") -> try again without zeros
            miss = mapped.isna() & s.notna()
            if miss.any():
                mapped[miss] = s[miss].str.lstrip('0').map(m)
            s = mapped.where(mapped.notna(), s)
        cols[c] = s
        names[c] = f"{cb[c]['label']} ({c})" if c in cb and cb[c]['label'] else c
    return pd.DataFrame(cols).rename(columns=names)

# ---------------------------------------------------------------- I/O
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--codebook', required=True)
    ap.add_argument('--data', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--chunk', type=int, default=50000, help='rows per chunk for csv input')
    a = ap.parse_args()

    cb = parse_codebook(a.codebook)
    maps = build_maps(cb)
    print(f'Codebook variables parsed: {len(cb)}')

    ext = os.path.splitext(a.data)[1].lower()
    out_xlsx = a.out.lower().endswith('.xlsx')

    if ext in ('.csv', '.tsv', '.txt'):
        sep = ',' if ext == '.csv' else '\t'
        reader = pd.read_csv(a.data, sep=sep, dtype=str, keep_default_na=False, chunksize=a.chunk)
        if out_xlsx:
            df = pd.concat(reader)
            res = decode_df(df, cb, maps)
        else:
            first = True; n = 0
            # open the output file ONCE and keep it open (avoids Windows "Permission denied" on re-open)
            with open(a.out, 'w', encoding='utf-8-sig', newline='') as fh:
                for chunk in reader:
                    res = decode_df(chunk, cb, maps)
                    res.to_csv(fh, header=first, index=False)
                    fh.flush()
                    first = False; n += len(chunk); print(f'  {n:,} rows done')
            print('Saved ->', a.out); report(df_cols=res.columns, cb=cb); return
    else:
        print('Reading Excel (can be slow for very large files; converting to CSV first is faster)...')
        df = pd.read_excel(a.data, dtype=str, keep_default_na=False)
        res = decode_df(df, cb, maps)

    if out_xlsx:
        try:
            import xlsxwriter  # noqa
            with pd.ExcelWriter(a.out, engine='xlsxwriter', engine_kwargs={'options': {'constant_memory': True}}) as w:
                res.to_excel(w, sheet_name='Decoded', index=False)
        except ImportError:
            res.to_excel(a.out, sheet_name='Decoded', index=False)
    else:
        res.to_csv(a.out, index=False, encoding='utf-8-sig')
    print(f'Saved -> {a.out}  ({len(res):,} rows, {res.shape[1]} columns)')
    report(res.columns, cb)

def report(df_cols, cb):
    undecoded = [c for c in df_cols if not re.search(r'\(.+\)$', str(c))]
    if undecoded:
        print('Columns not found in codebook (left unchanged):', ', '.join(map(str, undecoded)))

if __name__ == '__main__':
    main()

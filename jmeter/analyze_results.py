import csv
from collections import defaultdict

def _mean(data):
    return sum(data) / len(data) if data else 0

def _percentile(data, p):
    s = sorted(data)
    k = (len(s) - 1) * p / 100
    lo, hi = int(k), min(int(k) + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)

def load_csv(filepath, fieldnames=None):
    rows = []
    with open(filepath, newline='') as f:
        if fieldnames:
            reader = csv.DictReader(f, fieldnames=fieldnames)
        else:
            reader = csv.DictReader(f)
        for row in reader:
            if row.get('label') == 'GET Articles':
                rows.append({
                    'timestamp': int(row['timeStamp']),
                    'elapsed': int(row['elapsed']),
                    'success': row.get('success', 'true').lower() == 'true',
                    'threadName': row.get('threadName', '')
                })
    return sorted(rows, key=lambda r: r['timestamp'])

def calc_metrics(rows, name):
    if not rows:
        print(f"  {name}: sem dados")
        return
    elapsed = [r['elapsed'] for r in rows]
    errors = [r for r in rows if not r['success']]
    timestamps = [r['timestamp'] for r in rows]
    duration_s = (max(timestamps) - min(timestamps)) / 1000
    throughput = len(rows) / duration_s if duration_s > 0 else 0

    print(f"  {name}:")
    print(f"    Requisições:   {len(rows)}")
    print(f"    Tempo médio:   {_mean(elapsed):.1f} ms")
    print(f"    Percentil 95:  {_percentile(elapsed, 95):.1f} ms")
    print(f"    Throughput:    {throughput:.2f} req/s")
    print(f"    Taxa de erro:  {len(errors)/len(rows)*100:.1f}%")

SCENARIO_MAP = {
    'Cenario 1': "Cenário 1 - Carga Básica (10 threads, 60s)",
    'Cenario 2': "Cenário 2 - Carga Crescente (50 threads, 90s)",
    'Cenario 3': "Cenário 3 - Pico (100 threads, 30s)",
}

files = {
    'Protótipo 1 (sem auth)': {
        'path': 'jmeter/results/prototype-1-results.csv',
        'fieldnames': None
    },
    'Protótipo 2 (JWT)': {
        'path': 'jmeter/results/prototype-2-results.csv',
        'fieldnames': None
    },
    'Protótipo 3 (JWT+Cache)': {
        'path': 'jmeter/results/prototype-3-results.csv',
        'fieldnames': None
    },
}

for proto_name, config in files.items():
    print(f"\n{'='*55}")
    print(f"{proto_name}")
    print(f"{'='*55}")
    rows = load_csv(config['path'], config['fieldnames'])
    print(f"Total de amostras GET Articles: {len(rows)}")

    # Group by Thread Group prefix (first two words of threadName)
    groups = defaultdict(list)
    for r in rows:
        # threadName format: "Cenario X - Carga ... X-Y"
        # extract scenario key from first word pair e.g. "Cenario 1"
        parts = r['threadName'].split(' ')
        key = f"{parts[0]} {parts[1]}" if len(parts) >= 2 else 'Unknown'
        groups[key].append(r)

    for key in ['Cenario 1', 'Cenario 2', 'Cenario 3']:
        scenario_rows = groups.get(key, [])
        calc_metrics(scenario_rows, SCENARIO_MAP.get(key, key))

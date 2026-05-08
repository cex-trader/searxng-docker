#!/bin/sh

if [ -n "$PROXY_SOCKS5" ] || [ -n "$PROXY_HTTP" ]; then
    /usr/local/searxng/.venv/bin/python3 << 'PYEOF'
import yaml, os

path = '/etc/searxng/settings.yml'
with open(path, 'r') as f:
    settings = yaml.safe_load(f)

proxies = []
socks5 = os.environ.get('PROXY_SOCKS5', '')
http_proxy = os.environ.get('PROXY_HTTP', '')

if socks5:
    proxies.append(f'socks5h://{socks5}')
if http_proxy:
    proxies.append(f'http://{http_proxy}')

if proxies:
    settings.setdefault('outgoing', {})
    settings['outgoing']['proxies'] = {'all://': proxies}
    settings['outgoing'].setdefault('request_timeout', 5.0)
    settings['outgoing'].setdefault('max_request_timeout', 15.0)
    settings['outgoing']['using_tor_proxy'] = False

    with open(path, 'w') as f:
        yaml.dump(settings, f, default_flow_style=False, allow_unicode=True)
    print(f'[proxy] injected: {proxies}')
else:
    print('[proxy] variables set but empty, skipping')
PYEOF
else
    echo '[proxy] no PROXY_SOCKS5 or PROXY_HTTP set, direct connection'
fi

exec /usr/local/searxng/entrypoint.sh

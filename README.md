<!--
Do not edit this file. Edit 'docs/templates/README.md.j2' instead and run 'make README.md'.
-->

# envcat

[![Build](https://github.com/busyloop/envcat/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/busyloop/envcat/actions/workflows/ci.yml?query=branch%3Amaster) [![GitHub](https://img.shields.io/github/license/busyloop/envcat)](https://en.wikipedia.org/wiki/MIT_License) [![GitHub release](https://img.shields.io/github/release/busyloop/envcat.svg)](https://github.com/busyloop/envcat/releases)

<img src="https://github.com/busyloop/envcat/raw/master/assets/mugshot.png" alt="🐟" width="342" align="right" />

**Your Shell Environment Swiss Army Knife.** 🇨🇭

### Features

* Print environment variables in JSON, YAML or other formats
* Validate your environment variables
* Populate a template with env-variables from stdin to stdout

<sub><b>Hint:</b> envcat loves templating config-files in a Docker or Kubernetes environment.</sub>

<br>

## Installation

#### Download static executable

| OS           | Arch    | Version               |      |
| ------------ | ------- | --------------------- | ---- |
| macOS (Darwin) | x86_64  | 1.1.1 (latest)  | [Download](https://github.com/busyloop/envcat/releases/latest) |
| Linux        | x86_64  | 1.1.1 (latest)  | [Download](https://github.com/busyloop/envcat/releases/latest) |
| Linux        | aarch64 | 1.1.1 (latest)  | [Download](https://github.com/busyloop/envcat/releases/latest) |

#### macOS :beer:

`brew install busyloop/tap/envcat`

#### Dockerfile

See the [download page](https://github.com/busyloop/envcat/releases/latest) for an example Dockerfile. :whale:


## Usage

```bash
# Print
envcat '*'                           # Print all env vars in JSON-format
envcat -f yaml SHELL HOME            # Print $SHELL and $HOME in YAML-format

# Validate
envcat -c ADDR:ipv4                  # Exit 1 if $ADDR is undefined or not an IPv4 address
envcat -c ADDR:?ipv4                 # Exit 1 if $ADDR is defined and not an IPv4 address

# Template
echo "{{HOME}}" | envcat -f j2 '*'   # Read j2 template from stdin and render it to stdout
echo "{{HOME}}" | envcat -f j2 'H*'  # Same, but only vars starting with H available in the template

# All of the above combined
echo "{{BIND}}:{{PORT | default('443')}} {{NAME}}" | envcat -f j2 -c PORT:?port -c BIND:ipv4 PORT BIND NAME
```

:bulb: See `envcat --help` for full syntax reference.


## Templating

With `-f j2`, or when called by the name `envtpl`, envcat renders a jinja2 template from _stdin_ to _stdout_.  
Environment variables are available as `{{VAR}}`.

envcat will abort with code 5 if your template references an undefined variable,  
so make sure to provide defaults where appropriate: `{{VAR | default('xxx')}}`.


#### Examples


```bash
export FOO=a,b,c
export BAR=41
unset NOPE

echo "{{FOO}}"                                          | envcat -f j2 FOO  # => a,b,c
echo "{{NOPE | default('empty')}}"                      | envcat -f j2 NOPE # => empty
echo "{% for x in FOO | split(',') %}{{x}}{% endfor %}" | envcat -f j2 FOO  # => abc
echo "{% if FOO == 'd,e,f' %}A{% else %}B{% endif %}"   | envtpl FOO        # => B
echo "{% if BAR | int + 1 == 42 %}yes{% endif %}"       | envtpl BAR        # => yes
```


## Template syntax

Envcat supports most jinja2 syntax and [builtin filters](https://jinja.palletsprojects.com/en/2.11.x/templates/#list-of-builtin-filters).

On top it provides the following additional filters:

#### b64encode, b64encode_urlsafe

```bash
export FOO="hello? world?"

# b64encode, b64encode_urlsafe
echo "{{FOO | b64encode}}"                              | envtpl FOO  # => aGVsbG8/IHdvcmxkPw==
echo "{{FOO | b64encode_urlsafe}}"                      | envtpl FOO  # => aGVsbG8_IHdvcmxkPw==
```

#### b64decode

```bash
export B64_REGULAR="aGVsbG8/IHdvcmxkPw=="
export B64_URLSAFE="aGVsbG8_IHdvcmxkPw=="

echo "{{B64_REGULAR | b64decode}}"                      | envtpl 'B*' # => hello? world?
echo "{{B64_URLSAFE | b64decode}}"                      | envtpl 'B*' # => hello? world?
```

#### split


```bash
export FOO=a,b,c

echo "{% for x in FOO | split(',') %}{{x}}..{% endfor %}" | envtpl FOO  # => a..b..c..
```

**Note:**  
Envcat uses a [Crystal implementation of the jinja2 template engine](https://straight-shoota.github.io/crinja/).  
Python expressions are **not** supported.

## Layering data from multiple sources

By default envcat reads variables only from your shell environment.  
With `-i` you can additionally source data from YAML, JSON or TOML files.  
With `-s` you can override variables directly on the command line.

Both flags can be given multiple times.

**Examples:**

```bash
# Override vars with YAML file
$ export FOO=from_env
$ echo "foo: from_file" >demo.yaml
$ envcat -i env -i yaml:demo.yaml FOO
{"FOO":"from_file"}

# Override a var with `-s`
$ envcat -i env -i yaml:demo.yaml -s FOO=from_arg FOO
{"FOO":"from_arg"}

# Layer data from foo.yaml, the environment,
# JSON from stdin and lastly override FOO
$ envcat -i yaml:foo.yaml -i env -i json:- -s FOO=bar [..]
```

### Input normalization

envcat flattens the structure of data sourced via `-i` as follows.

Given the following YAML:

```yaml
# demo.yaml
employee:
  name: Jane Smith
  department: HR
  contact:
    email: jane@example.com
    phone: 555-123-4567
  projects:
    - Project A
    - Project B
  skills:
    - Skill 1
    - Skill 2
```

`envcat -f yaml -i yaml:demo.yaml '*'` produces the following output:

```yaml
EMPLOYEE_NAME: Jane Smith
EMPLOYEE_DEPARTMENT: HR
EMPLOYEE_CONTACT_EMAIL: jane@example.com
EMPLOYEE_CONTACT_PHONE: 555-123-4567
EMPLOYEE_PROJECTS_0: Project A
EMPLOYEE_PROJECTS_1: Project B
EMPLOYEE_SKILLS_0: Skill 1
EMPLOYEE_SKILLS_1: Skill 2
```


## Checks

With `-c VAR[:SPEC]` envcat checks that $VAR meets a constraint defined by SPEC.

This flag can be given multiple times.  
envcat aborts with code 1 if any check fails.

You can prefix a SPEC with `?` to skip it when $VAR is undefined:

```bash
unset FOO
envcat -c FOO:i     # => Abort because FOO is undefined
envcat -c FOO:?i    # => Success because FOO is undefined (check skipped)

export FOO=x
envcat -c FOO:i     # => Abort because FOO is not an unsigned integer
envcat -c FOO:?i    # => Abort because FOO is not an unsigned integer

export FOO=1
envcat -c FOO:i     # => Success because FOO is an unsigned integer
envcat -c FOO:?i    # => Success because FOO is an unsigned integer
```

For a full list of available SPEC constraints see below.


## Synopsis

```
Usage: envcat [-i <SOURCE> ..] [-s <KEY=VALUE> ..] [-c <VAR[:SPEC]> ..] [-f etf|kv|export|j2|j2_unsafe|json|none|yaml] [GLOB[:etf] ..]

  -i, --input=SOURCE      env|json:PATH|yaml:PATH|toml:PATH (default: env)
  -s, --set=KEY=VALUE     KEY=VALUE
  -f, --format=FORMAT     etf|export|j2|j2_unsafe|json|kv|none|yaml (default: json)
  -c, --check=VAR[:SPEC]  Check VAR against SPEC. Omit SPEC to check only for presence.
  -h, --help              Show this help
      --version           Print version and exit

SOURCE
  env           - Shell environment
  json:PATH     - JSON file at PATH
  yaml:PATH     - YAML file at PATH
  toml:PATH     - TOML file at PATH

FORMAT
  etf               Envcat Transport Format
  export            Shell export format
  j2                Render j2 template from stdin (aborts with code 5 if template references an undefined var)
  j2_unsafe         Render j2 template from stdin (renders undefined vars as empty string)
  json              JSON format
  kv                Shell format
  none              No format
  yaml              YAML format

SPEC
  alnum             must be alphanumeric
  b64               must be base64
  f                 must be an unsigned float
  fs                must be a path to an existing file or directory
  fsd               must be a path to an existing directory
  fsf               must be a path to an existing file
  gt:X              must be > X
  gte:X             must be >= X
  hex               must be a hex number
  hexcol            must be a hex color
  i                 must be an unsigned integer
  ip                must be an ip address
  ipv4              must be an ipv4 address
  ipv6              must be an ipv6 address
  json              must be JSON
  lc                must be all lowercase
  len:X:Y           must be X-Y characters
  lt:X              must be < X
  lte:X             must be <= X
  n                 must be an unsigned float or integer
  nre:X             must not match PCRE regex: X
  port              must be a port number (0-65535)
  re:X              must match PCRE regex: X
  sf                must be a float
  si                must be an integer
  sn                must be a float or integer
  uc                must be all uppercase
  uuid              must be a UUID
  v                 must be a semantic version
  vgt:X             must be a semantic version > X
  vgte:X            must be a semantic version >= X
  vlt:X             must be a semantic version < X
  vlte:X            must be a semantic version <= X

  Prefix ? to skip check when VAR is undefined.
```

## Advanced: Envcat Transport Format 🚚

Sometimes it can be helpful to pack multiple env vars
into a single string, to be unpacked elsewhere.  
You can do this with envcat by using the `etf` format:

```bash
$ export A=1 B=2 C=3

# Export to ETF format (url-safe base64)
$ envcat -f etf A B C
H4sIAPPtsmMA_6tWclSyUjJU0lFyAtJGQNoZSBsr1QIActF58hkAAAA

# Import from ETF format
# The :etf suffix tells envcat to unpack $VARS_ETF from etf format.
# The unpacked vars override any existing env vars by the same name.
$ export VARS_ETF=H4sIAPPtsmMA_6tWclSyUjJU0lFyAtJGQNoZSBsr1QIActF58hkAAAA
$ envcat -f export VARS_ETF:etf A B C
export A=1
export B=2
export C=3
```

You can also layer multiple ETF bundles:


```bash
$ export BUNDLE_A=$(A=xxx envcat -f etf A)
$ export BUNDLE_B=$(A=hello B=world envcat -f etf A B)

$ envcat -f export BUNDLE_A:etf A B
export A=xxx

$ envcat -f export BUNDLE_A:etf BUNDLE_B:etf A B
export A=hello
export B=world
```

## Exit codes

| Code  |                                                                                       |
| ----- | ------------------------------------------------------------------------------------- |
| 0     | Success                                                                               |
| 1     | Invalid value (`--check` constraint violation)                                        |
| 3     | Syntax error (invalid argument or template)                                           |
| 5     | Undefined variable access (e.g. your template contains `{{FOO}}` but $FOO is not set) |
| 7     | I/O Error                                                                             |
| 11    | Parsing error                                                                         |
| 255   | Bug (unhandled exception)                                                             |

## Contributing

1. Fork it (<https://github.com/busyloop/envcat/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


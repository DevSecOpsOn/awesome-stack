# Age section

age is a simple, modern and secure file encryption tool, format, and Go library.

It features small explicit keys, no config options, and UNIX-style composability.

```(shell)
$ age-keygen -o key.txt
Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrkmnasuh389asj
$ tar cvz ~/data | age -r age1ql3z7hjy54pw35ayyfg7zqgvc7w3j2elw8zmrj2kg5sfnasuuanjdvc > data.tar.gz.age
$ age --decrypt -i key.txt data.tar.gz.age > data.tar.gz
```

### Ecrypting files

The below command find for files ending with `.env` under `.secrets` folder(only) encrypting and remove it afterwards.

```(shell)
for s in $(find . -type f -print -execdir .secrets {} \; | egrep ".env$"); do age -e -R ~/.ssh/id_rsa.pub -o $s.age $s && rm $s; done
```

#### Decrypting files

The below command find for files ending with `.age` under `.secrets` folder(only) decrypting it.

```(shell)
for s in $(find * -type f -print -execdir secrets {} +); do age -d -i ~/.ssh/id_rsa -o $(ls $s | awk -F '.' '{ print $1}')\.env $s ; done
```

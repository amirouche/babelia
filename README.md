# Babelia

**experimental**

## Introduction

Babelia is a privacy friendly, decentralized, open source, and
accessible search engine. Search has been an essential part of
knowledge acquisition from the dawn of time, whether it is antique
lexicographically ordered filing cabinets or nowadays computer-based
wonders such as Google, Bing, Yandex, and Baidu. From casual search to
help achieve common tasks such as cooking, keeping up with the news, a
regular dose of cat memes, or professional search such as science
research. Search is, and will remain, an essential daily-use tool, and
stires human progress forward.

Babelia aims to replace the use of privateer search engines with a
search engine that is open, hence under the control of the
commons. Babelia wants to be an easy to install, easy to use, easy to
maintain, no-code, personal search engine that can scale to billions
of documents, beyond a terabyte of text data, for under €100 a month
per Babelia instance.

## Software Bill of Materials

Backend:

- Chez Scheme (programming language)
- FoundationDB (database)
- SQLite LSM extension (database)
- libtls (bsd project, or curl)
- zstandard (facebook's compression library)
- blake3 (hash)
- argon2 (password hashing)

Frontend:

- JavaScript
- Bootstrap (styles)

Also:

- Debian (GNU/Linux distribution)
- nginx (HTTP proxy)

## License

See `LICENSE` file.

## ROADMAP

### Milestone 1 - Webui

The first goal is to build the user interface. For regular users, the
mighty input box will be featured with search results (called hits),
along a search pad... The operator will be presented how to populate
the knowledge base, how to control the crawler, along a dashboard to
display health, and sort out moderation requests.

### Milestone 2 - Boolean-Keyword Search Engine

The second step is to build the basis of the backend that can achieve
boolean-keyword search with exact-match, and negated keywords, without
the support of the operator `OR`. Also, I will create a program to
convert `.zim` files from kiwix.org into a SQLite LSM database, add
the ability to populate the database with files using the Web ARChive
format nicknamed `.warc`. At which point, it will make sense to
package Babelia in NixOS.

### Milestone 3 - Knowledge Base

In that step the goal is to create the backend that will allow to
create the knowledge base that gathers information about known
entities and their relatedness. At this point it will be possible to
display recognized entities on result page. The main goal being the
added possibility to travel to the right of the semantic continuum
through hops in relations between known entities and keywords from the
query.

### Milestone 4 - Crawler

The point of this milestone is to build a crawler (also known as
spider). Unlike a privateer spider, it does not aim to be very
fast. One of the main goal of Babelia is to be one stop solution for
your search need. Hence, the main feature of the crawler is to be well
integrated with the rest of search engine. It will be possible to
subscribe to RSS, and ATOM feeds. Also, it will be handy, to also
support firefox bookmarks. It will be possible to ignore URLs with
glob patterns. Also, the number of hops outside seed domains will also
be configureable to help escape the gilded cage.

### Milestone 5 - Moderation & Dashboard

Here the goal is to allow the operator of a Babelia instance curate
domains with the ability to delete indexed documents, or even purge a
domain that were flagged by an user.

## TODO

- [ ] Convoui: conversational user interface;
- [ ] untangle: callback-less event-loop for network io;
- [ ] HTTP: HTTP/1.1 request and response reader and writer;
  - [ ] WARC: reader and writer;
- [ ] kiwix2babelia: convert kiwix' `.zim` files to `.warc` that can
      be consumed by babelia;
- [ ] JSON: JSON reader and writer;
- [ ] libtls;
- [ ] FoundationDB bindings;
  - [ ] lexicographic packing and unpacking;
  - [ ] nstore;
  - [ ] vnstore;
  - [ ] bstore;
  - [ ] eavstore;
  - [ ] pstore;
- [ ] HTML: gumbo bindings or htmlprag;
- [ ] XML / microXML: see yxml;
  - [ ] ATOM: reader;
  - [ ] RSS: reader;
  - [ ] OPML: reader;
- [ ] robots.txt, see https://github.com/seomoz/reppy;
- [ ] libmagic bindings;
- [ ] argon2 bindings;
- [ ] blake3 bindings;
- [ ] zstandard bindings;

## Acknowledgements

[![Logo NLnet: abstract logo of four people seen from above](https://nlnet.nl/logo/banner.png)](https://NLnet.nl)

[![Logo NGI Zero: letterlogo shaped like a tag](https://nlnet.nl/image/logos/NGI0_tag.png)](https://NLnet.nl/NGI0)

This project was funded through the [NGI0
Discovery](https://nlnet.nl/discovery) Fund, a fund established by
NLnet with financial support from the European Commission's [Next
Generation Internet](https://ngi.eu) programme, under the aegis of DG
Communications Networks, Content and Technology under grant agreement
No 825322.

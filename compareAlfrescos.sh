#!/bin/bash

diff -qr /opt/OLD /opt/NEW 2>&1 |\
grep -vF                         \
 -e '.bin'                       \
 -e '.class'                     \
 -e '.css'                       \
 -e '.eot'                       \
 -e '.ftl'                       \
 -e '.gif'                       \
 -e '.ico'                       \
 -e '.install'                   \
 -e '.js'                        \
 -e '.less'                      \
 -e '.md'                        \
 -e '.MF'                        \
 -e '.png'                       \
 -e '.sample'                    \
 -e '.svg'                       \
 -e '.swf'                       \
 -e '.ttf'                       \
 -e '.woff'                      \
 -e 'BAK'                        \
 -e 'google'                     \
 -e 'licenses/'                  \
 -e 'module.properties'          \
 -e 'pom.properties'             \
 -e 'pom.xml'                    \
 -e 'ORIG'                       \
 -e '/logs'                      \
 -e '/java/'                     \
 -e 'tomcat/temp'                \
 -e 'tomcat/work'                ;

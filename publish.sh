#!/bin/bash

echo "Publish $BRANCH !"

java -version

echo "====================================="
echo "download DITA-OT"
echo "====================================="
wget https://github.com/dita-ot/dita-ot/releases/download/2.5.2/dita-ot-2.5.2.zip >> download.log 2>>download.log
echo "..."
tail -n 2 download.log

echo "====================================="
echo "extract DITA-OT"
echo "====================================="
unzip dita-ot-2.5.2.zip >> extract.log 2>>extract.log
head -n 10 extract.log
echo "..."

echo "====================================="
echo "download DITA-OT LW-DITA plugin"
echo "====================================="

wget https://github.com/oasis-tcs/dita-lwdita/archive/master.zip >> download.log 2>>download.log
echo "..."
tail -n 2 download.log

echo "====================================="
echo "extract DITA-OT LW-DITA to DITA-OT"
echo "====================================="

unzip master.zip -d dita-ot-2.5.2 >> extract.log 2>>extract.log
head -n 10 extract.log
echo "..."

mv dita-ot-2.5.2/dita-lwdita-master/org.oasis-open.xdita dita-ot-2.5.2/plugins/

echo "====================================="
echo "download WebHelp plugin"
echo "====================================="

wget https://www.oxygenxml.com/InstData/WebHelp/oxygen-webhelp-dot-2.x.zip  >> download.log 2>>download.log
echo "..."
tail -n 2 download.log

echo "====================================="
echo "extract WebHelp to DITA-OT"
echo "====================================="
unzip oxygen-webhelp-dot-2.x.zip >> extract.log 2>>extract.log
head -n 10 extract.log
echo "..."
cp -R com.oxygenxml.* dita-ot-2.5.2/plugins/

echo $WEBHELP_LICENSE | tr " " "\n" | head -3 | tr "\n" " " > licensekey.txt
echo "" >> licensekey.txt
echo $WEBHELP_LICENSE | tr " " "\n" | tail -8  >> licensekey.txt

echo "****"
cat licensekey.txt
echo "****"

cp licensekey.txt dita-ot-2.5.2/plugins/com.oxygenxml.webhelp.responsive/licensekey.txt


echo "====================================="
echo "Add Edit Link to DITA-OT"
echo "====================================="

# Add the editlink plugin
git clone https://github.com/oxygenxml/dita-reviewer-links plugins/
cp -R plugins/com.oxygenxml.editlink dita-ot-2.5.2/plugins/

echo "====================================="
echo "download Markdown plugin"
echo "====================================="

wget https://github.com/jelovirt/dita-ot-markdown/releases/download/1.1.0/com.elovirta.dita.markdown_1.1.0.zip >> download.log 2>>download.log
echo "..."
tail -n 2 download.log

echo "====================================="
echo "extract MarkDown plugin"
echo "====================================="
unzip com.elovirta.dita.markdown_1.1.0.zip -d dita-ot-2.5.2/plugins/com.elovirta.dita.markdown >> extract.log 2>>extract.log
head -n 10 extract.log
echo "..."

echo "====================================="
echo "integrate plugins"
echo "====================================="
cd dita-ot-2.5.2/
bin/ant -f integrator.xml 
cd ..

echo "====================================="
echo "download Saxon9"
echo "====================================="
wget http://downloads.sourceforge.net/project/saxon/Saxon-HE/9.7/SaxonHE9-7-0-10J.zip >> download.log 2>>download.log
echo "..."
tail -n 2 download.log

echo "====================================="
echo "extract Saxon9"
echo "====================================="
unzip SaxonHE9-7-0-10J.zip -d saxon9/ >> extract.log 2>>extract.log
head -n 10 extract.log
echo "..."

echo "Using REPOSITORY_URL $REPOSITORY_URL" 
SLUG=`echo $REPOSITORY_URL | sed 's/git@github.com://' | sed 's/https:\/\/.*github.com\///'`
echo "Slug: $SLUG"
USERNAME=`echo $SLUG | cut -d '/' -f 1`
REPONAME=`echo $SLUG | cut -d '/' -f 2`

echo "====================================="
echo "publish: $USERNAME/$REPONAME "
echo "====================================="
java -cp saxon9/saxon9he.jar:dita-ot-2.5.2/lib/xml-resolver-1.2.jar net.sf.saxon.Transform -xsl:publish/publish.xsl \
  -it:main -catalog:dita-ot-2.5.2/catalog-dita.xml ghuser=$USERNAME ghproject=$REPONAME ghbranch=$BRANCH \
  oxygen-web-author=https://www.oxygenxml.com/oxygen-xml-web-author/app/oxygen.html
mkdir -p out/wiki/simple
mv out/wiki/*.html out/wiki/simple

MDTOPICS=`ls -1 wiki/*.md | sed -e 's/$/,/' | tr -d "\n" | sed -e 's/,$//'`

echo "====================================="
echo "generate map"
echo "====================================="
java -cp saxon9/saxon9he.jar:dita-ot-2.5.2/lib/xml-resolver-1.2.jar net.sf.saxon.Transform -xsl:publish/generateMap.xsl \
  -it:main -catalog:dita-ot-2.5.2/catalog-dita.xml ghuser=$USERNAME ghproject=$REPONAME ghbranch=$BRANCH \
  oxygen-web-author=https://www.oxygenxml.com/oxygen-xml-web-author/app/oxygen.html mdtopics="$MDTOPICS" title="$TITLE"
cat map.ditamap

# Send some parameters to the "editlink" plugin as system properties
export ANT_OPTS="$ANT_OPTS -Deditlink.remote.ditamap.url=github://getFileContent/$USERNAME/$REPONAME/$BRANCH/map.ditamap"
# Send parameters for the Webhelp styling.
export ANT_OPTS="$ANT_OPTS -Dwebhelp.fragment.welcome='$WELCOME'"

#export ANT_OPTS="$ANT_OPTS -Dwebhelp.responsive.template.name=bootstrap" 
#export ANT_OPTS="$ANT_OPTS -Dwebhelp.responsive.variant.name=tiles"
export ANT_OPTS="$ANT_OPTS -Dwebhelp.publishing.template=dita-ot-2.5.2/plugins/com.oxygenxml.webhelp.responsive/templates/$TEMPLATE/$TEMPLATE-$VARIANT.opt"

dita-ot-2.5.2/bin/dita -i map.ditamap -f webhelp-responsive -o out/wiki
echo "====================================="
echo "index.html"
echo "====================================="
cat out/wiki/index.html



echo "====================================="
echo "simple/index.html"
echo "====================================="
cat out/wiki/simple/index.html || echo "out/wiki/simple/index.html - not found"

#!/usr/bin/perl
use mobile;
use building;
use player;
use places;
use items;
use backpack;
use Data::Dumper;
use CGI::Fast;
use Storable qw (nstore store retrieve);


my $player;

&init() if($ARGV[0] eq "init");

%players = %{retrieve("data/players.db")};
$places = ${retrieve("data/places.db")};

$player = $players{1};



while($q = new CGI::Fast)
{
    my $store = 0; # if non-zero, save state to disk when time;
    #$q=new CGI;
    print $q->header;
    print "<head><title>Bannack</title>\n";

    print "</head>\n";
    print "<body>\n";
    local $cmds = $ENV{'QUERY_STRING'};



    if($cmds eq "cmd=playerinput")
    {
        my $input=$q->param('input');
        open(FH, ">>log.txt");
        print FH "\n".localtime(time).": ";

        if($input =~ /go (\d+),(\d+),(\d+)/)
        {
            $player->setPlace("$1,$2,$3");
            $player->setMessage( " setting place to $1,$2,$3 ");
        }
        $player->goInside() if($input eq "go inside");
        $player->goOutside($places) if($input eq "go outside");

        if( $input =~ /add (\w+)/ )
        {
            my $b = $1;
            $player->addItemPlace($places, ${b}->new);
        }

        if($input eq "buy axe")
        {
            my $b = $player->getBackpack();
            $b->add_items(axe->new);
            print FH "b=$b $input";
        }
        if($input eq "use candle")
        {
            $player->setMessage( " you light the candle in your backpack ");
            $player->setStatus( "Your candle burns brightly lighting the area around you" );
            ++$store;

        }
        nstore \%players, "data/players.db";
        nstore \$places, "data/places.db";
        close FH;
        exit;next;
    }
    if($cmds eq "cmd=getmainstatus")
    {
        print "<pre>".$player->getart()."</pre>";
        next;;next;
    }
    if($cmds eq "cmd=getplayerstatus")
    {
        print "Good evening ".$player->firstName()." ".$player->lastName().". Welcome to Montana (1865)";

        print "<p/>You are [".$player->getXYZ()."] ".$player->getPlaceDescription.".";
        print "<br/>".$player->getStatus();
        my @weather = ("It starts to snow", "It continues to snow", "The sky is sunny.");
        print "<p/>\n";
        print "It is snowing outside and bitterly cold.";#$weather[rand(scalar @weather)];
        next;;next;
    }
    if($cmds eq "cmd=getworldstatus")
    {
        print "debug:";
        print ++$hits;
        print "<br />player current place: ".$player->getPlace->getName;
        print "<pre><small>";
        print Dumper $places;
        print Dumper %players;
        print "</small></pre>";
        #print "<br>axe uses: ".$player->getBackpack()->getItem("axe")->getUses();#->items->axe->uses();
        #print "<br>axe weight: ".$player->getBackpack()->getItem("axe")->weight();#->items->axe->uses();
        print "<br><a href=?cmd=restart>restart</a>\n";
        #print "<br> place: ".$places->findPlace("200,100,0")->{_name};
        #print "<br>backpack:\n";
        #print $candle->weight();
        print "<pre><small>";

        print Dumper %map;
        #print Dumper $places;
        print "</small></pre>.\n";
        next;;next;
    }






    &mainstatus_js();
    print "<script>initmainstatus()</script>\n";
    &playerstatus_js();
    print "<script>initplayerstatus()</script>\n";
    &worldstatus_js();
    print "<script>initworldstatus()</script>\n";

    print "<div style=\"border-style: none;\" id=\"mainstatus\" style=\"width: 80%\">\n";
    print "</div>\n";
    print "<br clear=\"both\">\n";

    print "<div id=\"left\" style=\"border-style: double;float: left; width: 48%; height: 100%\">\n";
    print "<div id=\"playerstatus\" style=\"border-style: none;float: left; width: 100%;\"></div>\n";
    print "<div id=\"playerinput\" style=\"border-style: none;float: left; width: 100%;\">\n";
    print <<XXX;
<script type="text/javascript" src="js/ajaxsbmt.js"></script>
<form name="MyForm" action="main.fcgi" method="post" onsubmit="xmlhttpPost('main.fcgi?cmd=playerinput', 'MyForm', 'MyResult', ''); return false;"> 

XXX
    print "What would you like to do? ";
    print $q->textfield(-name=>'input', -style=>'border: dashed 1px;');
    print $q->end_form();
    print "\n</div>\n";
    print "<div id=\"MyResult\" style=\"border-style: none;float: left; width: 100%;height: 100%;\"></div>\n";
    print "</div>\n";
    
    print "<div id=\"right\" style=\"border-style: double;float: right; width: 48%;\">\n";
    
    print "<div id=\"worldstatus\" style=\"overflow: auto;border-style: none;float: left; width: 100%;\"></div>\n";
    
    print "</div>\n";

    exit if($cmds eq "cmd=restart");
}

sub init
{
    my $player = new player( "Nicholas", "Thiebalt", 200, 100, 0, 1 );
    my $bag = backpack->new(color => 'brown');
    $bag->add_items(
        candle->new,
        );
    $player->setBackpack($bag);
    $players{1} = $player;
    nstore \%players, "data/players.db";

    my $places = new places();
    my $place = new place( "merchant", "general store", "George", "Crisman", 1000, 2, 10, 0, 1 );
    $places->addPlace( $place );
    $place = new place( "cabin", "cabin", "Nicholas", "Thiebalt", 1, 200, 100, 0, 1 );
    $places->addPlace( $place );

    nstore \$places, "data/places.db";
    exit;
}

sub mainstatus_js
{
    print <<XXX;
<script type="text/javascript">
function initmainstatus()
{
    //gamestatus();
    setInterval("mainstatus()", 1000);
}
function mainstatus()
{

    var xmlhttp;
    if (window.XMLHttpRequest)
    {// code for IE7+, Firefox, Chrome, Opera, Safari
         xmlhttp=new XMLHttpRequest();
    }
    else
    {// code for IE6, IE5
         xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=function()
    {
        if (xmlhttp.readyState==4 && xmlhttp.status==200)
        {
            var response = xmlhttp.responseText;
            document.getElementById("mainstatus").innerHTML=response;//.substr(0,offset);
        }
    }
    xmlhttp.open("GET","?cmd=getmainstatus",true);
    xmlhttp.send();
}
</script>
XXX
}

sub playerstatus_js
{
    #my $cmdargs = "getgamestatus";
    print <<XXX;
<script type="text/javascript">
function initplayerstatus()
{
    //gamestatus();
    setInterval("playerstatus()", 1000);
}
function playerstatus()
{

    var xmlhttp;
    if (window.XMLHttpRequest)
    {// code for IE7+, Firefox, Chrome, Opera, Safari
         xmlhttp=new XMLHttpRequest();
    }
    else
    {// code for IE6, IE5
         xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=function()
    {
        if (xmlhttp.readyState==4 && xmlhttp.status==200)
        {
            var response = xmlhttp.responseText;
            document.getElementById("playerstatus").innerHTML=response;//.substr(0,offset);
        }
    }
    xmlhttp.open("GET","?cmd=getplayerstatus",true);
    xmlhttp.send();
}
</script>
XXX
}
sub worldstatus_js
{
    #my $cmdargs = "getgamestatus";
    print <<XXX;
<script type="text/javascript">
function initworldstatus()
{
    //gamestatus();
    setInterval("worldstatus()", 1000);
}
function worldstatus()
{

    var xmlhttp;
    if (window.XMLHttpRequest)
    {// code for IE7+, Firefox, Chrome, Opera, Safari
         xmlhttp=new XMLHttpRequest();
    }
    else
    {// code for IE6, IE5
         xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.onreadystatechange=function()
    {
        if (xmlhttp.readyState==4 && xmlhttp.status==200)
        {
            var response = xmlhttp.responseText;
            document.getElementById("worldstatus").innerHTML=response;//.substr(0,offset);
        }
    }
    xmlhttp.open("GET","?cmd=getworldstatus",true);
    xmlhttp.send();
}
</script>
XXX
}

sub formjs
{
    print <<XXX;
<script type="text/javascript">
function foo(strURL,formname,responsediv,responsemsg) {
    var xmlHttpReq = false;
    var self = this;
    // Xhr per Mozilla/Safari/Ie7
    if (window.XMLHttpRequest) {
        self.xmlHttpReq = new XMLHttpRequest();
    }
    // per tutte le altre versioni di IE
    else if (window.ActiveXObject) {
        self.xmlHttpReq = new ActiveXObject("Microsoft.XMLHTTP");
    }
    self.xmlHttpReq.open('POST', strURL, true);
    self.xmlHttpReq.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    self.xmlHttpReq.onreadystatechange = function() {
        if (self.xmlHttpReq.readyState == 4) {
			// Quando pronta, visualizzo la risposta del form
            updatepage(self.xmlHttpReq.responseText,responsediv);
        }
		else{
			// In attesa della risposta del form visualizzo il msg di attesa
			updatepage(responsemsg,responsediv);

		}
    }
    self.xmlHttpReq.send(getquerystring(formname));
}

function getquerystring(formname) {
    var form = document.forms[formname];
	var qstr = "";

    function GetElemValue(name, value) {
        qstr += (qstr.length > 0 ? "&" : "")
            + escape(name).replace(/\+/g, "%2B") + "="
            + escape(value ? value : "").replace(/\+/g, "%2B");
			//+ escape(value ? value : "").replace(/\n/g, "%0D");
    }
	
	var elemArray = form.elements;
    for (var i = 0; i < elemArray.length; i++) {
        var element = elemArray[i];
        var elemType = element.type.toUpperCase();
        var elemName = element.name;
        if (elemName) {
            if (elemType == "TEXT"
                    || elemType == "TEXTAREA"
                    || elemType == "PASSWORD"
					|| elemType == "BUTTON"
					|| elemType == "RESET"
					|| elemType == "SUBMIT"
					|| elemType == "FILE"
					|| elemType == "IMAGE"
                    || elemType == "HIDDEN")
                GetElemValue(elemName, element.value);
            else if (elemType == "CHECKBOX" && element.checked)
                GetElemValue(elemName, 
                    element.value ? element.value : "On");
            else if (elemType == "RADIO" && element.checked)
                GetElemValue(elemName, element.value);
            else if (elemType.indexOf("SELECT") != -1)
                for (var j = 0; j < element.options.length; j++) {
                    var option = element.options[j];
                    if (option.selected)
                        GetElemValue(elemName,
                            option.value ? option.value : option.text);
                }
        }
    }
    return qstr;
}
function updatepage(str,responsediv){
    document.getElementById(responsediv).innerHTML = str;
}
</script>
XXX
}

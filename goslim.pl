#---------------------------------------  
#   程序：GOslim 基因分类  
#   版本：0.1 
#   作者：zoe  
#   日期：2015-06-11 
#   语言：Perl 
#--------------------------------------- 

#!/usr/bin/perl -w
use strict;
use DBI;
use CGI;
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;

$CGI::POST_MAX = 1024 * 5000;
my $safe_filename_characters = "a-zA-Z0-9_.-";
my $upload_dir = "./TMP";

my $query = new CGI;
my $filename = $query->param("filename");
my $text = $query->param("seq");
$text=~s/^\s+|\s+$//g;
my $data=$query->param("database");
my $Ontologies=$query->param("Ontologies");
my $seqname =$query->param("name");

my ( $name, $path, $extension ) = fileparse ( $filename, '..*' );
$filename = $name . $extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;

if($text ne ""){
$filename=$seqname.$$;
open (OUT,">$upload_dir/$filename");
print OUT $text;
close(OUT);
}elsif($filename){
my $upload_filehandle = $query->upload("filename");
open ( UPLOADFILE, ">$upload_dir/$filename" ) or die "$!";
binmode UPLOADFILE;

while ( <$upload_filehandle> )
{
print UPLOADFILE;
}

close UPLOADFILE;
}
print "Content-Type: text/html; charset=utf-8\n\n";

my $infile="./TMP/".$filename;
my $outfile = "./TMP/goslim.txt";
my $printfile = "./TMP/print.txt";

print <<END_HTML;
<html>
<head>
<link href="../css/bio.css" rel="stylesheet" type="text/css" />
<style>pre{font-family:monospace}</style>

</head>
<body>
<center><h2 class="title2">GOslim 基因分类</h2></center>
<table id="mytab"  border="1" class="t1" style="text-indent: 0em">

<td>
GO term ID
</td>
<td>
Description
</td>
<td>
type
</td>
<td>
num
</td>
END_HTML

my $driver   = "mysql";
my $database = "soybean";
my $dsn = "DBI:$driver:dbname=$database;host=localhost";
my $userid = "root";
my $password = "123";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })or die $DBI::errstr;

open(IN,"<$infile");
my @lines = <IN>;
close (IN);
open(FH,">","$outfile") or die "Can not open $outfile:$!";

my $total;
my $j=0;
for(my $i = 0; $i < @lines; $i++){
     my @fields = split(/\s+/,$lines[$i]);
 
#导出到文件 
my $sth = $dbh->prepare("SELECT goslim_ID  from tbl_goslim where input_accession like '%@fields%'");
if($sth ne ""){$j++;}
$sth->execute();
while(my @elem = $sth->fetchrow)
{
 print FH "@elem,@fields,$j\n";
}

	 my $sql="SELECT goslim_ID,goslim_name,num,type,input_accession  from tbl_goslim where input_accession like '%@fields%'";
 
if ($i==0)
{ $total=$sql;}
else
{ $total=$sql." UNION ".$total;}
	
}
   
my $sth=$dbh->prepare($total);	 
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

#清空数据表，将txt导入到数据库
my $sth = $dbh->prepare("truncate table tbl_nowtime");
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){ print $DBI::errstr;}

close (FH);
system("perl insert_mysql.pl -a DBI:mysql -d soybean -u root -p 123 -i goslim.txt");

open(PT,">","$printfile") or die "Can not open $printfile:$!";

my $sth = $dbh->prepare("select goslim_ID,gmax,count(*) from tbl_nowtime group by goslim_ID;");
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){ print $DBI::errstr;}
while(my @upd = $sth->fetchrow)
{
 print PT "$upd[0],$upd[1],$upd[2]\n";
}
#清空数据库表 tbl_pttime
my $sth = $dbh->prepare("truncate table tbl_pttime");
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){ print $DBI::errstr;}
close (PT);
#将txt数据插入到数据库表  tbl_pttime
system("perl prt_mysql.pl -a DBI:mysql -d soybean -u root -p 123 -i print.txt");


#三表关联查询
my $sth = $dbh->prepare("select a.goslim_ID,max(c.num),b.goslim_name,b.type from tbl_nowtime as a inner join tbl_goslim b on a.goslim_ID=b.goslim_ID inner join tbl_pttime c on b.goslim_ID=c.goslim_ID group by a.goslim_ID;");
my $rv = $sth->execute() or die $DBI::errstr;
if($rv < 0){
   print $DBI::errstr;
}

while(my @row = $sth->fetchrow_array()) {     
print <<EOM;
<tr>
<td>
EOM
	  print "<a href=\"http://amigo.geneontology.org/amigo/term/$row[0]\">$row[0]</a> ";
print <<EOM;
</td>
<td>
EOM
	 print "$row[2] ";
print <<EOM;
</td>
<td>
EOM
	print "$row[3] ";
print <<EOM;
</td>
<td>
EOM
	  print "<a href=\"http://www.stsystemsbiology.com/cgi-bin/goslim_gene.pl?gene=$row[0]\">$row[1]</a> "; #字符”转义
print <<EOM;
</td>
</tr>
EOM

}

$sth->finish();
$dbh->disconnect();
    

print <<EOM;

</table>
</body>
</html>
EOM
system("rm ./TMP/*$filename*");

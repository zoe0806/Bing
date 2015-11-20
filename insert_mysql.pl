use warnings;
use strict;
#数据库模块
use DBI;
#解析命令行
use Getopt::Long;
## Used to output the 'usage' message
use Pod::Usage;

#命令：perl mysql.pl -a DBI:mysql -d soybean -u root -p 111  -i test.txt

sub ReadInLocusBriefFile{
     my $infile = shift; 
     my @result = (); 
	my ($seq_id,$seq_desc,$seq_data);
     open (INFILE, "<$infile") || die "Can't open $infile\n"; 
	 my $first_column = 1;
	 while(<INFILE>){
		#第一行忽略
		#if($first_column){
		#	$first_column = 0;
		#	next;
		#}
		chomp;
		#匹配序列正确
		if(/(.*?)[,](.*?)[,](.*)?/){
			push @result,[($1,$2,$3)];
		}else{
			print $_."\n";
		}
	 }
	 close(INFILE); 
     return (@result); 
}



my $dsn = "DBI:mysql:soybean";
my $adaptor = "DBI::mysql";
my $user = '';
my $password = '';
my $infile = '';
my $create = 0;

my $summary_stats	= 0;
my $nosummary_stats  = 0;

my $opt_help;
my $opt_man;

GetOptions( 'd|dsn=s'			=> \$dsn,
	    'a|adaptor=s'		=> \$adaptor,
	    'c|create'			=> \$create,
	    'u|user=s'			=> \$user,
	    'p|password=s'		=> \$password,
		'i|infile=s'		=> \$infile,
	    ## I miss '--help' when it isn't there!
	    'h|help!'			=> \$opt_help,
	    'm|man!'			=> \$opt_man,
)
	or pod2usage( -message =>
		"\nTry 'go_slim_assignment_2_mysql.pl --help' for more information\n",
		-verbose => 0,
		-exitval => 2,
	      );

## Should we output usage information?
pod2usage( -verbose => 1 ) if $opt_help;
pod2usage( -verbose => 2 ) if $opt_man;

	  
my ($dbh,$sth,@ary);
#连接数据库
$dsn = $adaptor .":"."database=".$dsn.";host=localhost";
#print $dsn." user: " . $user . " password:".$password;
$dbh = DBI->connect($dsn,$user,$password);

#将fasta文件读到数组中
my @result = ReadInLocusBriefFile($infile);
#将fasta文件写到数据库中
my $table_name = 'tbl_nowtime';

#$infile =~ /^(.*)\.\w+$/;
#$infile = $1;

$sth = $dbh->prepare("INSERT INTO $table_name(goslim_ID,gmax,num) values(?,?,?)");
foreach my $line(@result){
	my ($goslim_ID,$gmax,$num) = ($line->[0],$line->[1],$line->[2]);
	$sth->execute($goslim_ID,$gmax,$num);
}
$sth->finish();
$dbh->disconnect();

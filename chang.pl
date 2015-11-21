#---------------------------------------  
#   程序：替换  
#   版本：0.1 
#   作者：zoe  
#   日期：2015-07-11 
#   语言：Perl 
#   功能：用tab(2)文件的gene name 去替代 fasta(1) 文件中的 gene id 
#--------------------------------------- 

#!/usr/bin/perl -w
use autodie;

open TABLE,"$ARGV[0]" || die $!;
open FASTA,"$ARGV[1]" || die $!;
while(<TABLE>)
    {    chomp;
        @F=split /[\s:]+/,$_;     
        $change{$F[0]}=$F[11];
    }
while(<FASTA>)
   {
        if(/^>/)
        {
           @F=split /\s+/,$_;
           ($id=$F[0])=~s/^>//;
           if($change{$id})
           {
                $_=~s/$id/$change{$id}/
           }
        }
        print
    };

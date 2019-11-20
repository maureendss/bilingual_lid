#########################################################################################################
###  save-small-files.praat
###
### Saves little sound files from one big sound file.
###  
### Opens a soundfile as a LongSound object and reads in its associated TextGrid file.
###
### Extracts the portion of the sound file corresponding to all non-empty intervals on a specified tier,
### with an optional buffer on each end.
###
### Saves each extracted portion to a .wav file named:
### (<prefix>)<interval label>_<time_value>(<suffix>).wav
###
### NB: The time value (in seconds to two decimal places) of the beginning of the segment
### in the original sound file is included in the file name. 
###
### This disambiguates between two tokens of the same word and also allows one to find the word 
### in the longer sound file, if need be. 
###
### Creates and saves a (optionally labelled) TextGrid file for each word.
###
### Creates a text file named:
### <orginal long sound file name>_list.txt
### that contains a list of all the .wav files created. Useful for keeping track of what came from where.
###
###
### Praat 4.3.29
###
### Pauline Welby  welby@icp.inpg.fr
### October 28, 2004
###
#########################################################################################################

#  form that asks user for the directories containing file to be worked on, 
#  and for other information 

form Input directory name with final slash
    comment Enter parent directory where sound file  is kept:
    sentence soundDir C:\Users\idarcy\Desktop\Praat_Data\Chisato
    comment Enter directory where TextGrid file is kept:
    sentence textDir C:\Users\idarcy\Desktop\Praat_Data\Chisato
    comment Enter directory to which created sound files should be saved:
    sentence outDir C:\Users\idarcy\Desktop\Praat_Data\Chisato
    comment Specify tier name:
    sentence tierName silences
    comment Specify length of left and right buffer (in seconds):
    positive margin 0.05
    comment Specify minimum length of segment (in seconds):
    positive minsegm 0.5
    comment Optional prefix:
    sentence prefix 
    comment Optional suffix (.wav will be added anyway):
    sentence suffix 
    comment Append time point?
    boolean append_time no
    comment Enter basename of soundfile (without .wav extension)
    sentence baseFile saakuru
endform

# create a directory for the output files
createDirectory: outDir$

# delete any existing record file
filedelete 'outDir$'\'baseFile$'_list.txt

numberOfFiles = 1
for ifile to numberOfFiles
  # Read in the Sound and TextGrid files
  #Read from file... C:\Users\idarcy\Desktop\Praat_Data\Chisato\saakuru.TextGrid
  Read from file... 'textDir$'\'baseFile$'.TextGrid
  Open long sound file... 'soundDir$'\'baseFile$'.wav

  # Go through tiers and extract info

  select TextGrid 'baseFile$'

  nTiers = Get number of tiers
    for i from 1 to 'nTiers'
      tname$ = Get tier name... 'i'

        if tname$ = "'tierName$'"

        # Find non-empty intervals
	
        nInterv = Get number of intervals... 'i'
        for j from 1 to 'nInterv'
        lab$ = Get label of interval... 'i' 'j'
          if lab$ != ""

            # Get time values for start and end of the interval

            begwd = Get starting point... 'i' 'j'			      
            endwd = Get end point... 'i' 'j'
	   
            if 'endwd'-'begwd' >= 'minsegm'
 
	           # Add buffers, if specified

	           begfile = 'begwd'-'margin'
	           endfile = 'endwd'+'margin' 

	           # Create and save small .wav file

	           select LongSound 'baseFile$'

	           Extract part... 'begfile' 'endfile' yes

	           if append_time = 1

	             Write to WAV file... 'outDir$'\'prefix$''lab$'-'begwd:2''suffix$'.wav

	           else

	             Write to WAV file... 'outDir$'\'prefix$''lab$'_'begwd:1''suffix$'.wav

	           endif

	          # Write label of each saved interval to a text file (keeps a record of origin of small soundfiles)

	          fileappend 'outDir$'\'baseFile$'_list.txt 'prefix$''lab$'_'begwd:1''suffix$'.wav 'newline$'

	          ## Object cleanup
	          select Sound 'baseFile$'
	          Remove

	          ## Re-select TextGrid
	          select TextGrid 'baseFile$'

            endif

          endif
	
    endfor

endfor

# Complete object cleanup
select TextGrid 'baseFile$'
plus LongSound 'baseFile$'
Remove

select TextGrid 'baseFile$'
Remove
####### END OF SCRIPT #######
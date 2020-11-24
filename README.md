# LID

Language IDentification system
- Insipred from Carbajal's Experiment 6 in the modeling chapter



## Replicating Results from de Seyssel & Dupoux, 2020

1. Fill out the `kaldi_setup/cmd.sh` and `kaldi_setup/path.sh` accordingly with your setup.

2. Create a `wavs` directory and add link to all wav files from EMIME in `data/emime/wavs` *(On Oberon, you can use the `data/emime/wavs_oberon.txt` file containing the path of all used wavs to create the directory.*

3. Link all files from `kaldi_setup` and `abx` into appropriate local folders (this is where the output of your experiments will go). *Consider creating this local folders into a place with enough storage*.
   ```
   mkdir -p local/kaldi_setup
   mkdir -p local/abx
   cd local/kaldi_setup && ln -s ../../kaldi_setup/* . && cd ../..
   cd local/abx && ln -s ../../abx/* . && cd ../..
   ```

4. Activate Conda Environment.  __TODO : Give info on env__
5. Run local/run_cogsci.sh : `cd local/kaldi_setup && local/run_cogsci.sh`

6. Run the ABX tests : `cd ../abx/ && ./run_by_spk.sh EMIME-controlled`

7. Retrieve the scores : `./retrieve_scores.sh EMIME-controlled > EMIME-controlled.byspk.scores.txt

*Note : Results are prone to minor changes due to the randomness in computing MFCC features*

--------------------

[de Seyssel, M. & Dupoux, E. (2020). Does bilingual input hurt? A simulation of language discrimination and clustering using i-vectors. In *Proceedings for the Annual Meeting of the Cognitive Science Society 2020*](https://cognitivesciencesociety.org/cogsci20/papers/0683/0683.pdf)
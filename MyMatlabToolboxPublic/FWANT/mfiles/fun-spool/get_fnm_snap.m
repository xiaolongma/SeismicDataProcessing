function [fnm_snap]=get_fnm_snap(pnm,prefix,n_i,n_j,n_k,id,n)

fnm_snap=[pnm  '/' prefix num2str(id,'%3.3i') '_mpi' ...
            num2str(n_i,'%2.2i')...
            num2str(n_j,'%2.2i')...
            num2str(n_k,'%2.2i') ...
            '_n' num2str(n,'%5.5i') '.nc'];

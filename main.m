function [] = main(outdir)

%disp('Loading config.json...');

% load my own config.json
%config = loadjson('config.json');

% create output directory
mkdir(fullfile(pwd, outdir));

%# function sptensor

%% load inputs

disp('Loading data...');

% create the labels
%labs = config.parc;
%mask = config.mask;
infl = 3;
%labs = niftiRead('parc.nii.gz');
%mask = niftiRead('mask.nii.gz');

%nnodes = config.nnodes;
microlab = 'fa';
%microdat = niftiRead(config.fa);
microdat = niftiRead('fa.nii.gz');

% import streamlines
%fg = dtiImportFibersMrtrix(config.fibers, .5);
fg = dtiImportFibersMrtrix('track.tck', .5);

% grab length
fascicle_length = cellfun(@(x) sum(sqrt(sum((x(:, 1:end-1) - x(:, 2:end)) .^ 2))), fg.fibers, 'UniformOutput', true);

% create the inflated parcellation
parc = feInflateLabels('parc.nii.gz', 'mask.nii.gz', infl, 'vert', fullfile(pwd, outdir, 'labels_dilated.nii.gz'));

%% create the inputs

disp('Assigning streamlines to connections...');

% assign the initial connections - pass dummy weights
[ pconn, rois ] = feCreatePairedConnections(parc, fg.fibers, fascicle_length, ones(size(fascicle_length)));

% catch the center in an output
centers = nan(size(rois, 1), 3);
for ii = 1:size(rois)
    centers(ii, 1) = rois{ii}.centroid.acpc(1);
    centers(ii, 2) = rois{ii}.centroid.acpc(2);
    centers(ii, 3) = rois{ii}.centroid.acpc(3);
end

clear ii 

%% central tendency of microstructure

disp('Computing central tendency of edge FA...');
pconn = fnAverageEdgePropertyS(pconn, 'all', fg, microdat, microlab, 'mean');
pconn = fnAverageEdgePropertyS(pconn, 'all', fg, microdat, microlab, 'std');

%% create matrices

disp('Creating connectivity matrices...');
[ omat, olab ] = feCreateAdjacencyMatrices(pconn, 'all');

%% run network statistics

disp('Computing network statistics...');

% for every matrix computed
for ii = 1:size(omat, 3)
    
    % compute a bunch of numbers
    [ stats.(olab{ii}).glob, stats.(olab{ii}).node, stats.(olab{ii}).nets ] = fnNetworkStats(omat(:,:,ii));
    
end

%% save and exit

disp('Saving outputs...');

% save the matlab outputs for debugging
save(fullfile(pwd, outdir, 'omat.mat'), 'omat');
save(fullfile(pwd, outdir, 'olab.mat'), 'olab');
save(fullfile(pwd, outdir, 'pconn.mat'), 'pconn');
save(fullfile(pwd, outdir, 'rois.mat'), 'rois');

% save text outputs - convert writes to json
dlmwrite(fullfile(pwd, outdir, 'centers.csv'), centers, ',');
dlmwrite(fullfile(pwd, outdir, 'count.csv'), omat(:,:,1), ',');
dlmwrite(fullfile(pwd, outdir, 'density.csv'), omat(:,:,2), ',');
dlmwrite(fullfile(pwd, outdir, 'length.csv'), omat(:,:,3), ',');
dlmwrite(fullfile(pwd, outdir, 'denlen.csv'), omat(:,:,4), ',');

% save microstructure mats if they're made
dlmwrite(fullfile(pwd, outdir, 'fa_mean.csv'), omat(:,:,5), ',');
dlmwrite(fullfile(pwd, outdir, 'fa_std.csv'), omat(:,:,6), ',');

% save all the network stats
opt.filename = fullfile(pwd, outdir, 'stats.json');
opt.ArrayIndent = 1;
opt.ArrayToStruct = 0;
opt.SingleArray = 0;
opt.SingletCell = 0;
opt.Compact = 1;
savejson('stats', stats, opt);

end

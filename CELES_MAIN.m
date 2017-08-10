% ======================================================================
%> @brief Run this script to start the simulation
% ======================================================================

% -------------------------------------------------------------------------
% do not edit
% -------------------------------------------------------------------------

% add all folders to the matlab search path
addpath(genpath('.'))

% initialize the celes class instances
simulation = celes_simulation;
particles = celes_particles;
initialField = celes_initialField;
input = celes_input;
numerics = celes_numerics;
solver = celes_solver;
preconditioner = celes_preconditioner;
output = celes_output;


% -------------------------------------------------------------------------
% begin of user editable section - specify the simulation parameters here
% -------------------------------------------------------------------------

% complex refractive index of particles, n+ik
particles.refractiveIndex = 2;

% radii of particles
% must be an array with same number of columns as the position matrix
% e.g. particles.radiusArray = ones(1,100)*100;
particles.radiusArray = rand(1,100)*181;

% positions of particles (in three-column format: x,y,z)
positions = zeros(100,3);
[pos_x, pos_y] = meshgrid(linspace(-18000,18000,10)',linspace(-18000,18000,10));
positions(:,1) = pos_x(:);
positions(:,2) = pos_y(:);
particles.positionArray = positions;

% polar angle of incoming beam/wave, in radians (for Gaussian beams, 
% only 0 and pi are currently possible)
initialField.polarAngle = 0;

% azimuthal angle of incoming beam/wave, in radians
initialField.azimuthalAngle = 0;

% polarization of incoming beam/wave ('TE' or 'TM')
initialField.polarization = 'TE';

% width of beam waist (use 0 or inf for plane wave)
initialField.beamWidth = 20000;

% focal point 
initialField.focalPoint = [0,0,0];

% vacuum wavelength (same unit as particle positions and radius)
input.wavelength = 1000;

% complex refractive index of surrounding medium
input.mediumRefractiveIndex = 1;

% maximal expansion order of scattered fields (around particle center)
numerics.lmax = 3;

% resolution of lookup table for spherical Hankel function (same unit as
% wavelength)
numerics.particleDistanceResolution = 1;

% use GPU for various calculations (deactivate if you experience GPU memory 
% problems - translation operator always runs on gpu, even if false)
numerics.gpuFlag = true;

% sampling of polar angles in the plane wave patterns (radians array)
numerics.polarAnglesArray = 0:1e-2:pi;

% sampling of azimuthal angles in the plane wave patterns (radians array)
numerics.azimuthalAnglesArray = 0:1e-2:2*pi;

% specify solver type (currently 'BiCGStab' or 'GMRES')
solver.type = 'BiCGStab';   

% relative accuracy (solver stops when achieved)
solver.tolerance=1e-4;

% maximal number of iterations (solver stops if exceeded)
solver.maxIter=1000;

% restart parameter (only for GMRES)
solver.restart=20;

% monitor progress? in that case, a self-written script is used rather than
% matlab's built-in bicgstab/gmres
solver.monitor=true;

% type of preconditioner (currently only 'blockdiagonal' and 'none'
% possible)
% Must be 'none' if particles have different radii
preconditioner.type = 'none';

% for blockdiagonal preconditioner: edge size of partitioning cuboids
preconditioner.partitionEdgeSizes = [1500,1500,1500];

[x,z] = meshgrid(-18000:10:18000,-3000:10:5000); y=x-x;
% specify the points where to evaluate the electric near field (3-column
% array x,y,z)
output.fieldPoints = [x(:),y(:),z(:)];

% dimensions of the array used to restore the original shape of x,y,z 
% for display of 2d-images
output.fieldPointsArrayDims = size(x);

% -------------------------------------------------------------------------
% end of user editable section
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% do not edit
% -------------------------------------------------------------------------

% combine all parameters to one simulation object
input.particles = particles;
input.initialField = initialField;
solver.preconditioner = preconditioner; 
numerics.solver = solver;
simulation.input = input;
simulation.numerics = numerics;
simulation.tables = celes_tables;
simulation.output = output;
simulation.tables.particles = particles;

% compute
simulation=simulation.run;
simulation=simulation.evaluatePower;
simulation=simulation.evaluateFields;

% view output
figure
plot_field(gca,simulation,'abs E','Scattered field',simulation.input.particles.radiusArray)
colormap(jet)
caxis([0,1])

figure
plot_spheres(gca,simulation.input.particles.positionArray,simulation.input.particles.radiusArray,'view xy')
colormap(jet)
caxis([0,1])

fprintf('transmitted power: %f %%\n',simulation.output.totalFieldForwardPower/simulation.output.initialFieldPower*100)
fprintf('reflected power: %f %%\n',simulation.output.totalFieldBackwardPower/simulation.output.initialFieldPower*100)
function o = compile(o, varargin)
%function o = compile(o)
% Compile Report Object
%
% INPUTS
%   o            [report]  report object
%   varargin     [char]    allows user to change report compiler for a
%                          given run of compile.
%
% OUTPUTS
%   o     [report]  report object
%
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2013-2014 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

opts.compiler = o.compiler;
opts.showReport = true;
opts.showOutput = o.showOutput;

if nargin > 1
    if round((nargin-1)/2) ~= (nargin-1)/2
        error('@report.compile: options must be supplied in name/value pairs');
    end

    optNames = fieldnames(opts);

    % overwrite default values
    for pair = reshape(varargin, 2, [])
        ind = find(strcmpi(optNames, pair{1}));
        assert(isempty(ind) || length(ind) == 1);
        if ~isempty(ind)
            opts.(optNames{ind}) = pair{2};
        else
            error('@report.compile: %s is not a recognized option.', pair{1});
        end
    end
end

assert(ischar(opts.compiler), '@report.compile: compiler file must be a string');
assert(islogical(opts.showReport), '@report.compile: showReport must be either true or false');
assert(islogical(opts.showOutput), '@report.compile: showOutput must be either true or false');

if ~exist(o.fileName, 'file')
    o.write();
end

middle = ' ./';
options = '-synctex=1';
if isoctave
    echo = 1;
else
    echo = '-echo';
end
if isempty(opts.compiler)
    if strncmp(computer, 'MACI', 4) || ~isempty(regexpi(computer, '.*apple.*', 'once'))
        % Add most likely places for pdflatex to exist outside of default $PATH
        if opts.showOutput
            [status, opts.compiler] = ...
                system(['PATH=$PATH:/usr/texbin:/usr/local/bin:/usr/local/sbin;' ...
                        'which pdflatex'], echo);
        else
            [status, opts.compiler] = ...
                system('PATH=$PATH:/usr/texbin:/usr/local/bin:/usr/local/sbin;which pdflatex');
        end
    elseif strcmp(computer, 'PCWIN') || strcmp(computer, 'PCWIN64')
        if opts.showOutput
            [status, opts.compiler] = system('findtexmf --file-type=exe pdflatex', echo);
        else
            [status, opts.compiler] = system('findtexmf --file-type=exe pdflatex');
        end
        middle = ' ';
        opts.compiler = ['"' strtrim(opts.compiler) '"'];
    else % gnu/linux
        if opts.showOutput
            [status, opts.compiler] = system('which pdflatex', echo);
        else
            [status, opts.compiler] = system('which pdflatex');
        end
    end
    assert(status == 0, ...
           '@report.compile: Could not find a tex compiler on your system');
    opts.compiler = strtrim(opts.compiler);
    o.compiler = opts.compiler;
end

if opts.showOutput
    status = system([opts.compiler ' ' options middle o.fileName], echo);
else
    [status, junk] = system([opts.compiler ' ' options middle o.fileName]);
end
[junk, rfn, junk] = fileparts(o.fileName);

if status ~= 0
    error(['@report.compile: There was an error in compiling ' rfn '.pdf.' ...
          '  ' compiler ' returned the error code: ' num2str(status)]);
end
if o.showOutput || opts.showOutput
    fprintf(1, 'Done.\n');
    disp('Your compiled report is located here:');
    disp(['     ' pwd filesep rfn '.pdf']);
end
if opts.showReport && ~isoctave
    open([pwd filesep rfn '.pdf']);
end
end
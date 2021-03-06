function S = wmsImport(varargin)
%WMSIMPORT Import variables from WMS Database
%
%   S = WMSIMPORT imports all the variables of the WMS database into the
%   scalar structure S. The complete list of variables are defined below.
%
%   S = WMSIMPORT(fieldVar1, fieldVar2, fieldVar3, ...) imports the
%   specified variables into the struct, S.  S contains fields matching the
%   variables retrieved. The fieldVar variables are strings and must match
%   one or more of the following names listed below. (If fieldVar does not
%   match one of the following, it is ignored.) The case of fieldVar does
%   not matter.
%
%   Name               Data Type        Field Content
%   -----              ---------        -------------
%   ServerTitle        String array     Title of the server 
%
%   ServerURL          String array     URL of the server
%
%   LayerTitle         String array     Title of the layer
%
%   LayerName          String array     Name of the layer
%
%   ServerTitleIndex   Double array     Indices 
%
%   ServerURLIndex     Double array     Indices
%
%   LayerTitleIndex    Double array     Indices
%
%   LayerNameIndex     Double array     Indices
%
%   Latlim             Double array     Southern and northern latitude
%                                       limits of the layer
%
%   Lonlim             Double array     Western and eastern longitude
%                                       limits
%
%   Meta               Struct           Database meta information
%
%   The Meta structure contains meta information for the database and
%   contains the following fields:
% 
%   Name               Data Type     Field Content
%   ----               ---------     --------
%   Version            String        Version of database
%
%   Date               String        Date of creation
%
%   NumLayers          Double        Number of layers
%
%   NumServers         Double        Number of servers
% 
%   ServerTitle, ServerURL, LayerTitle, and LayerName are cell arrays
%   comprising unique elements which were generated by applying UNIQUE to
%   complete lists containing redundant entries. The original size of each
%   list, prior to calling UNIQUE, is stored in Meta.NumLayers. The *Index
%   variables are the J index variables from UNIQUE. These *Index variables
%   can be used to reconstruct the string cell arrays to their original
%   size.
%
%   The Latlim and Lonlim variables are double arrays of size
%   Meta.NumLayers-by-2.
%
%   See also WMSFIND.

% Copyright 2008 The MathWorks, Inc.
% $Revision: 1.1.6.1 $  $Date: 2008/05/12 21:26:35 $

% Assign fieldVars and stringVars from the inputs.
[fieldVars, stringVars] = assignFieldVars(varargin{:});

% Assign the filename of the database.
filename = 'wmsdatabase';

% Load each variable into the output structure. If fieldVars is empty, all
% variables are loaded.
S = load(filename,fieldVars{:});

% All requested stringVars are stored as numeric elements and need to be
% converted to string.
S = convertElementVars(S, stringVars);

%--------------------------------------------------------------------------

function [fieldVars, stringVars] = assignFieldVars(varargin)
% Assign fieldVars and stringVars based on VARARGIN inputs. 
%
% fieldVars is a cell array of strings containing valid variable names that
% can be loaded from the WMS MAT-file.  
%
% stringVars is a cell array of strings that define the variables in the
% WMS MAT-file that are documented as string variables by the interface,
% but are actually stored as numeric values.

% Assign fieldVars from the input variables.
fieldVars = varargin;

% fieldVars is allowed to be empty.
if ~isempty(fieldVars)    
    
    % validFieldVars contains all variable names in the WMS MAT-file.
    validFieldVars = { ...
        'ServerTitle', 'ServerURL', ...
        'LayerTitle',  'LayerName', ...
        'ServerTitleIndex', 'ServerURLIndex', ...
        'LayerTitleIndex',  'LayerNameIndex', ...
        'Latlim', 'Lonlim', 'Meta'};

    % The input variable names may be lower case and may contain extra
    % names that are not valid.  Assign each element of fieldVars to its
    % matching element in validFieldVars, ignoring case. If an element in
    % fieldVars is not found in validFieldVars, then set the element to ''.
    fcn = @(x) getValidFieldVar(x, validFieldVars);
    fieldVars = cellfun(fcn, fieldVars, 'UniformOutput', false);

    % Remove any variables not found; those that have been set to '' by
    % getValidFieldVar.
    isEmptyIndex = cellfun(@isempty, fieldVars);
    fieldVars(isEmptyIndex) = [];
    
    % Only need the unique set.
    fieldVars = unique(fieldVars);

    % Assign validStringVars to those variables that are allowed by the
    % interface, but are stored as numeric values in the WMS MAT-file.
    validStringVars = ...
        {'ServerTitle', 'ServerURL', 'LayerTitle',  'LayerName'};

    % Find any members of fieldVars that contain the validStringVars.
    stringIndex = ismember(fieldVars, validStringVars);
    
    % Set the stringVars variables to those members of fieldVars that are
    % found in validStringVars.
    stringVars = fieldVars(stringIndex);
    
    % Remove the stringVars from fieldVars since these variable names are
    % not found in the WMS MAT-file.
    fieldVars(stringIndex) = [];

    % For all the stringVars, create the associated element variable names.
    [elementVars, elementSizeVars] = ...
        cellfun(@makeElementVars, stringVars, 'UniformOutput', false);

    % fieldVars contains members from validFieldVars, excluding the
    % stringVars which are now replaced with their corresponding element
    % names.
    fieldVars = [fieldVars elementVars elementSizeVars];

    % Remove any variables that have been set to ''.
    isEmptyIndex = cellfun(@isempty, fieldVars);
    fieldVars(isEmptyIndex) = [];

else
    
    % fieldVars is empty, so all the variables from the WMS MAT-file will
    % be loaded. However, all the stringVars need to be assigned for
    % post-processing.
    stringVars = {'ServerTitle', 'ServerURL', 'LayerTitle', 'LayerName'};
    
end

%--------------------------------------------------------------------------

function fieldVar = getValidFieldVar(fieldVar, validFieldVars)
% Return the element in the cell array validFieldVars that matches
% fieldVar, ignoring case. If a match is not found, return ''.

index = strcmpi(fieldVar, validFieldVars);
if ~any(index)
    % Ignore input not found in validFieldVars.
    fieldVar = '';
else
    % At this point, because validFieldVars contains a set of unique
    % elements, exactly one element of index is true and the rest are
    % false. The rhs below will evaluate to a single string.
    fieldVar = validFieldVars{index};
end

%--------------------------------------------------------------------------

function [element, elementSize] = makeElementVars(var)
% Create the names of the element variables from the input string var.

element = [var 'Element'];
elementSize = [var 'ElementSize'];

%--------------------------------------------------------------------------

function S = convertElementVars(S, stringVars)
% For each field in S that contains an element variable, convert it to a
% cell array of strings.

if ~isempty(stringVars)
    
    % elementFieldVars contains a list of all the fields of S that contain
    % the name 'Element' or 'ElementSize'. These element fields are private
    % fields in the WMS MAT-file and are used to improve performance. All
    % the elementsFieldVars will be removed from S.
    elementFieldVars = {};
    
    % Loop through each element of stringVars and convert the numeric
    % element field to a cell array of strings.
    for k=1:numel(stringVars)
        
        % From the stringVars name, make the element names.
        [elements, elementSize] = makeElementVars(stringVars{k});
        
        % Append the new element names to elementFieldVars.
        elementFieldVars(1, end+1:end+2) = {elements elementSize};
        
        % Convert the numeric element fields of S to a cell array of
        % strings. Append the cell array of strings to S, with a new field
        % name, the current element of stringVars.
        S.(stringVars{k}) = ...
            elements2cell(S.(elements), S.(elementSize));
    end
    
    % Remove the elementFieldVars from S since they are no longer needed
    % and are private fields.
    S = rmfield(S,elementFieldVars);
end

%--------------------------------------------------------------------------

function c = elements2cell(elements, elementSize)
% Convert the numeric array, elements, to a cell array of strings, c. The
% size of c is equal to the size of elementSize.  Each element of c will
% have a length defined by the corresponding element from the numeric array
% elementSize.

% Initialize c.
c = cell(1,numel(elementSize));

% Convert the numeric elements variable to a char array.
charElement = char(elements);

% Loop through each element of elementSize and assign the current element
% of c to its corresponding position in charElement.
startIndex = 1;
for k=1:numel(elementSize)
    
    % If an elementSize is 0, then assign ''.
   if elementSize(k) == 0
      c{k} = '';
   else
       % Assign the current element of c from startIndex:endIndex of
       % charElement.
       endIndex = elementSize(k) + startIndex - 1;
       c{k} = charElement(startIndex:endIndex);
   end

   % Increment startIndex by current elementSize.
   startIndex= startIndex + elementSize(k);
end

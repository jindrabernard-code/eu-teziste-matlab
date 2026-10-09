classdef EuMap < handle
%EUMAP Simple map of Europe on ordinary axes (no Mapping Toolbox needed).
%   m = EuMap(parent, latLim, lonLim, withLegend) draws the countries: EU
%   members light blue, the United Kingdom (member until 2020) lighter,
%   others grey, sea white. Data are then drawn with methods that take
%   geographic coordinates:
%       m.line(lat, lon, '-', 'Color', c)       ~ geoplot
%       m.scatter(lat, lon, sz, c, 'filled')    ~ geoscatter
%       m.text(lat, lon, 'label')
%   m.showMembers(members, former) recolours countries by membership (animation).
%   EuMap(..., withLegend, 'plain') draws every country in grey (no EU highlight).
%   m.Ax are the underlying axes (title, legend, colormap, colorbar, Layout).
%
%   Projection: equirectangular with standard parallel 50° N
%   (x = lon * cos 50°, y = lat). Good enough at the scale of Europe and,
%   above all, the same for every map in the project.
%   Borders: GISCO CNTR_RG_10M_2020, downloaded once into data/raw/.

    properties (Constant)
        K = cosd(50)
        EU_COLOR    = [0.74 0.85 0.97]
        UK_COLOR    = [0.87 0.92 0.98]
        OTHER_COLOR = [0.86 0.86 0.86]
        SEA_COLOR   = [1 1 1]
        EU_EDGE     = [0.55 0.70 0.90]
        OTHER_EDGE  = [0.97 0.97 0.97]
    end
    properties
        Ax
        Codes       % country codes (EL, UK, ...) in the order of Polys
        Polys       % Polygon handle for every country
        LegEU       % legend entries (empty patches), DisplayName can be changed
        LegFormer
    end

    methods
        function m = EuMap(parent, latLim, lonLim, withLegend, style)
            if nargin < 4, withLegend = false; end
            if nargin < 5, style = 'members'; end
            plain = strcmp(style, 'plain');
            if plain, withLegend = false; end      % no EU / UK legend entries
            m.Ax = axes(parent);
            ax = m.Ax;
            hold(ax, 'on');  box(ax, 'on');
            ax.Color = EuMap.SEA_COLOR;
            ax.Layer = 'top';  ax.GridColor = [0.4 0.4 0.4];  ax.GridAlpha = 0.15;
            grid(ax, 'on');
            [shapes, m.Codes] = EuMap.shapes();
            m.Polys = plot(ax, shapes, 'FaceAlpha', 1, 'LineWidth', 0.4, 'HandleVisibility', 'off');
            hv = 'off';  if withLegend, hv = 'on'; end
            m.LegEU = fill(ax, NaN, NaN, EuMap.EU_COLOR, 'EdgeColor', EuMap.EU_EDGE, ...
                'DisplayName', 'EU members (2025)', 'HandleVisibility', hv);
            m.LegFormer = fill(ax, NaN, NaN, EuMap.UK_COLOR, 'EdgeColor', EuMap.EU_EDGE, ...
                'LineStyle', ':', 'DisplayName', 'United Kingdom (member until 2020)', 'HandleVisibility', hv);
            C = readtable(fullfile(EuMap.root(), 'data', 'countries.csv'), 'TextType', 'string');
            if plain
                m.showMembers(strings(0));
            else
                m.showMembers(C.code(ismissing(C.leave_date) | C.leave_date == ""), "UK");
            end
            m.limits(latLim, lonLim);
        end

        function showMembers(m, members, former)
            % members blue, former members light blue, others grey
            if nargin < 3, former = strings(0); end
            isM = ismember(m.Codes, members);
            isF = ismember(m.Codes, former) & ~isM;
            set(m.Polys(~isM & ~isF), 'FaceColor', EuMap.OTHER_COLOR, 'EdgeColor', EuMap.OTHER_EDGE, 'LineStyle', '-');
            set(m.Polys(isM), 'FaceColor', EuMap.EU_COLOR, 'EdgeColor', EuMap.EU_EDGE, 'LineStyle', '-');
            set(m.Polys(isF), 'FaceColor', EuMap.UK_COLOR, 'EdgeColor', EuMap.EU_EDGE, 'LineStyle', ':');
        end

        function h = line(m, lat, lon, varargin)
            h = plot(m.Ax, lon * EuMap.K, lat, varargin{:});
        end

        function h = scatter(m, lat, lon, varargin)
            h = scatter(m.Ax, lon * EuMap.K, lat, varargin{:});
        end

        function h = text(m, lat, lon, str, varargin)
            h = text(m.Ax, lon * EuMap.K, lat, str, varargin{:});
        end

        function limits(m, latLim, lonLim)
            ax = m.Ax;
            axis(ax, 'equal');
            xlim(ax, lonLim * EuMap.K);  ylim(ax, latLim);
            step = nice_step(diff(lonLim));
            lonT = ceil(lonLim(1) / step) * step : step : lonLim(2);
            latT = ceil(latLim(1) / step) * step : step : latLim(2);
            ax.XTick = lonT * EuMap.K;  ax.YTick = latT;
            ax.XTickLabel = compose('%g°%s', abs(lonT'), string(ifelse(lonT' < 0, 'W', 'E')));
            ax.YTickLabel = compose('%g°N', latT');
        end
    end

    methods (Static)
        function r = root()
            r = fileparts(fileparts(mfilename('fullpath')));
        end

        function [S, codes] = shapes()
            % one polyshape per country (projected), kept in memory for the
            % session. Countries are kept separate: a union of all of them
            % would turn Switzerland into a hole and erase internal borders.
            persistent cS cCodes
            if ~isempty(cS), S = cS; codes = cCodes; return, end
            file = fullfile(EuMap.root(), 'data', 'raw', 'countries_10M_2020.geojson');
            if ~isfile(file)
                websave(file, ['https://gisco-services.ec.europa.eu/distribution/v2/' ...
                    'countries/geojson/CNTR_RG_10M_2020_4326.geojson'], weboptions('Timeout', 120));
            end
            js = jsondecode(fileread(file));
            F = js.features;
            if iscell(F), F = [F{:}]; end
            S = polyshape.empty;  codes = strings(0, 1);
            ws = warning('off', 'MATLAB:polyshape:repairedBySimplify');
            for i = 1:numel(F)
                rings = geojson_rings(F(i).geometry.coordinates);
                % Europe and surroundings only (faster drawing, no overseas territories)
                keep = cellfun(@(r) any(r(:, 2) > 25 & r(:, 2) < 75 & r(:, 1) > -35 & r(:, 1) < 60), rings);
                rings = rings(keep);
                if isempty(rings), continue, end
                xy = cellfun(@(r) [r(:, 1) * EuMap.K, r(:, 2); NaN NaN], rings, 'UniformOutput', false);
                xy = vertcat(xy{:});
                S(end+1) = polyshape(xy(:, 1), xy(:, 2)); %#ok<AGROW>
                codes(end+1, 1) = string(F(i).properties.CNTR_ID); %#ok<AGROW>
            end
            warning(ws);
            cS = S;  cCodes = codes;
        end
    end
end

function v = ifelse(c, a, b)
v = repmat(string(b), size(c));  v(c) = a;
end

function s = nice_step(span)
cands = [1 2 5 10];
s = cands(find(span ./ cands <= 9, 1));
if isempty(s), s = 10; end
end

classdef EuMap < handle
%EUMAP Jednoduchá mapa Evropy na obyčejných osách (bez Mapping Toolboxu).
%   m = EuMap(parent, latLim, lonLim, withLegend) nakreslí státy: členy EU
%   světle modře, Spojené království (člen do 2020) světleji, ostatní šedě,
%   moře bíle. Data se pak kreslí metodami se zeměpisnými souřadnicemi:
%       m.line(lat, lon, '-', 'Color', c)       ~ geoplot
%       m.scatter(lat, lon, sz, c, 'filled')    ~ geoscatter
%       m.text(lat, lon, 'popisek')
%   m.showMembers(clenove, byvali) přebarví státy podle členství (animace).
%   m.Ax jsou podkladové osy (title, legend, colormap, colorbar, Layout).
%
%   Projekce: ekvidistantní válcová se standardní rovnoběžkou 50° s. š.
%   (x = lon * cos 50°, y = lat). V měřítku Evropy dostatečné a hlavně
%   stejné pro všechny mapy projektu.
%   Hranice: GISCO CNTR_RG_10M_2020, stažené jednou do data/raw/.

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
        Codes       % kódy států (EL, UK, ...) v pořadí Polys
        Polys       % Polygon handle pro každý stát
        LegEU       % položky legendy (prázdné plochy), DisplayName lze měnit
        LegFormer
    end

    methods
        function m = EuMap(parent, latLim, lonLim, withLegend)
            if nargin < 4, withLegend = false; end
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
                'DisplayName', 'Členské státy EU (2025)', 'HandleVisibility', hv);
            m.LegFormer = fill(ax, NaN, NaN, EuMap.UK_COLOR, 'EdgeColor', EuMap.EU_EDGE, ...
                'LineStyle', ':', 'DisplayName', 'Spojené království (člen do 2020)', 'HandleVisibility', hv);
            C = readtable(fullfile(EuMap.root(), 'data', 'countries.csv'), 'TextType', 'string');
            m.showMembers(C.code(ismissing(C.leave_date) | C.leave_date == ""), "UK");
            m.limits(latLim, lonLim);
        end

        function showMembers(m, members, former)
            % členové modře, bývalí členové světle modře, ostatní šedě
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
            % polyshape pro každý stát (v projekci), drží se v paměti session.
            % Každý stát zvlášť: sjednocení do jednoho tvaru by ze Švýcarska
            % udělalo díru a zmizely by hranice mezi státy.
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
                % jen Evropa a okolí (zrychlí kreslení, zámoří nepotřebujeme)
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

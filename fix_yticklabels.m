function ht = fix_yticklabels(handle,margins,textopts)

%FIX_XTICKLABELS will determine maximum allowed width
%   of long XTickLabels and convert them into multiple line 
%   format to fit maximum allowed width
%
%
%   IN:
%       handle      [optional] - axes handle (defaults to gca)
%       margins     [optional] - relative margins width (defaults to 0.1)
%       texopts     [optional] - cell array of addtitional text formating
%                                options (defaults to {} )
%
%   OUT:
%       ht - column vector of handles for created text objects
%
% This code was derrived from MY_XTICKLABELS by Pekka Kumpulainen 
% http://www.mathworks.com/matlabcentral/fileexchange/19059-myxticklabels
%   EXAMPLE:
%       figure;
%
%       bar(rand(1,4));
%       set(gca,'XTickLabel',{'Really very very long text', ...
%                             'One more long long long text', ...
%                             'Short one','Long long long text again'});
%       fix_xticklabels();
%
%       figure;
%
%       bar(rand(1,4));
%       set(gca,'XTickLabel',{'Really very very long text', ...
%                             'One more long long long text', ...
%                             'Short one','Long long long text again'});
%       fix_xticklabels(gca,0.1,{'FontSize',16});
%

% Mikhail Erofeev 07.06.2013
% Pekka Kumpulainen 12.2.2008

if(~exist('handle','var'))
    handle = gca;
end

if(~exist('textopts','var'))
   textopts={};
end
if(~exist('margins','var'))
    margins = 0.1;
end

ytickpos = get(handle,'YTick');
ytickstring = get(handle,'YTickLabel');


set(handle, 'YTickLabel','')
h_olds = findobj(handle, 'Tag', 'MUXTL');
if ~isempty(h_olds)
    delete(h_olds)
end

%% Make XTickLabels 
NTick = length(ytickpos);
Ybot = get(handle,'YLim');

Xbot = min(get(handle,'XLim'));
xlims = get(handle,'XLim');
max_w = min(diff(ytickpos))*(1-margins);

ht = text(Xbot*ones(NTick,1) - margins*diff(xlims)/10,ytickpos',ytickstring, ...
    'Units','data', ...
    'VerticalAlignment', 'middle', ...
    'HorizontalAlignment', 'right ', ...
    'Tag','MUXTL');

if ~isempty(textopts)
    set(ht,textopts{:})
end

for ii = 1:NTick
    auto_width(ht(ii),max_w);
end



%% squeeze axis if needed

set(handle,'Units','pixels')
Axpos = get(handle,'Position');
% set(Hfig,'Units','pixels')
% Figpos = get(Hfig,'Position');

set(ht,'Units','pixels')
TickExt = zeros(NTick,4);
for ii = 1:NTick
    TickExt(ii,:) = get(ht(ii),'Extent');
end


ylabh = get(handle,'YLabel');

minleft = min(TickExt(:,1)); %Get leftmost data label
if( ~isempty(ylabh) )
    oldu = get(ylabh,'Units');
    set(ylabh,'Units','pixels');
    ext = get(ylabh,'Extent');
    pos = get(ylabh,'Position');
    pos(1) = minleft - ext(3);
    set(ylabh,'Position',pos);
    ext = get(ylabh,'Extent');
    minleft = ext(1);
    set(ylabh,'Units',oldu)
end

needmove = -(Axpos(1) + minleft);

if needmove>0;
    Axpos(1) = Axpos(1)+(needmove+20);
    Axpos(3) = Axpos(3)-(needmove+20);
    set(handle,'Position',Axpos);
end

set(handle,'Units','normalized')
set(ht,'Units','normalized')
end

function []=auto_width(h,maxw)
    str = h.String;    
    words = regexp(str,' ','split');
    h.String = words;
    height = h.Extent(4);    
    while height > maxw && max(size(h.String)) ~= 1
        minWidth = Inf;
        for i = 1:max(size(h.String))-1
            tempwords = {words{1:i-1},[words{i},' ',words{i+1}],words{i+2:end}};
            h.String = tempwords(~cellfun(@isempty,tempwords));
            if h.Extent(3) < minWidth
                minWidth = h.Extent(3);
                newWords = h.String;
            end
        end
        h.String = newWords;
        words = newWords;
        
        height = h.Extent(4);
    end
end

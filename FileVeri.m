classdef FileVeri < handle & matlab.mixin.CustomDisplay
properties(Access=?Veri)
    V
end
properties
    IND

    files
    dirs
    extra

    selVars
    selInd
%end
%properties(Access=protected)
    statReq
    iterReq
    statVar
    iterVar
    statVal
    iterVal

    fss

    bCnt
    cntReq
    Cnt
    bExpCnt

    KEYS
    keys
    Ind

    List
    Names
    Re
    bRe
    bDir
    bOptional
    bExpanded

    iter
    iterNames
    bExistIter
    bDirIter
    bOptIter
    bExpIter

    Orig
    cntOrig
end
methods(Static)
    function obj=test()

        dire=Dir.current();
        fname=[dire 'cfg/file_schema.cfg'];
        %fname=[dire 'cfg/Imap.config'];

        hash='0b745dcb5010fa9c5d9ef4d08d3f958e';
        db=dbInfo('LRSI');


        obj=FileVeri.read(fname,'mod','tbl','root',Env.var('imap.all'),'hash',hash,'I',db.gdImages,'LorR',{'L','R'});

    end
    function obj=readHard(fs_schema_fname,varargin)
        [fss,keys]=Cfg.read(fs_schema_fname);
        obj=FileVeri(fss);
        if nargin >=2
            obj.expand(true,varargin{:});
        end
        obj.isExpanded();
    end
    function obj=read(fs_schema_fname,varargin)
        [fss,keys]=Cfg.read(fs_schema_fname);
        assignin('base','fss',fss)
        obj=FileVeri(fss,keys);
        if nargin >=2
            obj.expand(false,varargin{:});
        end
        obj.isExpanded();
    end
end
methods
    function obj=FileVeri(fss,KEYS)
        % SEE;
        %   obj=FileVeri.read(...)
        %   obj=FileVeri.readSoftly(...)
        %
        %   obj.select()
        %   obj.expand()
        %   obj.get()
        %

        if nargin < 1
            return
        end
        if nargin > 1
        obj.KEYS=KEYS;
        end
        obj.fss=fss;
        obj.expand_schema;
        obj.IND=true(size(obj.Names));
        obj.Orig=obj.List;
        obj.cntOrig=obj.Cnt;

        obj.bOptional=startsWith(obj.Names,'?');
        obj.Names=regexprep(obj.Names,'^\?','');
        obj.Names=regexprep(obj.Names,'^-','');

        obj.get_stat_req();
        obj.get_iter_req();
        obj.get_cnt_req();

        obj.keys=obj.fss.keys;

        obj.identify();
    end
%%% ROOT
    function [out,full]=lsRoot(obj)
        [~,root]=obj.getVar('root');
        [out,full]=Dir.dirs(root{1});
    end
%%% Base
    function out=getCompletion(obj,name)
    end
    function out=archiveBase(obj,name)
    end
    function out=unarchiveBase(obj,name)
    end
    function out=backupBase(obj,name)
    end
    function out=rmBackupBase(obj,name)
    end
    function out=selectBase(obj,name)
        % XXX check to see if already selected
        % XXX
    end
    function out=delete(obj,name)
    end
    function out=existBase(obj,name)
        [~,root]=obj.getVar('root');
        out=Dir.exist([root{1} name]);
    end
    function lnBase(obj,name,alias)
        obj.exists();
        obj.ln_();
    end
    function rmLnBase(obj,name,alias)
    end
    function renameBase(obj,name,newname)
        obj.exists();
        obj.rename_();
    end
    function getTimestamp(obj)
    end
    function getLns(obj,name)
    end
%% REAL
    function timestamp(obj)
        % XXX
    end
    function clearAll(obj,bClearVars)
        if nargin < 1
            bClearVars=true;
        end
        obj.List=obj.Orig;
        obj.IND=true(size(obj.Names));
        obj.isExpanded;
        obj.Cnt=obj.cntOrig;
        if bClearVars
            for i = 1:length(obj.statVal)
                obj.statVal{i}=[];
            end
            for i = 1:length(obj.iterVal)
                obj.iterVal{i}=[];
            end
        end
    end
    function dir(obj)
        bind=~ismember(obj.Names,'root') & obj.bDir & obj.bExpanded;
        dirs=obj.List(bind);
        dirs(~cellfun(@Dir.exist,dirs))=[];
        [~,dirsStat]=cellfun(@Dir.dirs,obj.List(bind),'UniformOutput',false);
        obj.dirs=unique([dirs; vertcat(dirsStat{:})]);
        [~,fileStat]=cellfun(@Dir.files,obj.List(bind),'UniformOutput',false);
        obj.files=vertcat(fileStat{:});
    end
    function ls(obj)
        obj.dir();
        disp(obj.dirs);
        disp(obj.files);
    end
%% IDEAL
    function existsAll(obj)
        % TODO
        eStat=false(size(obj.stat));
        eStat(~obj.bDirStat)=cellfun(@Fil.exist,obj.stat(~obj.bDirStat));
        eStat(obj.bDirStat)=cellfun(@Dir.exist, obj.stat(obj.bDirStat));
        obj.bExistStat=eStat;

        eIter=false(size(obj.iter));
        eIter(:,~obj.bDirIter)=cellfun(@Fil.exist,obj.iter(:,~obj.bDirIter));
        eIter(:,obj.bDirIter)=cellfun(@Dir.exist, obj.iter(:,obj.bDirIter));
        obj.bExistIter=eIter;
    end
    function isExtra(obj)
        % TODO
        obj.exists();
        obj.dir();

        exdirs=obj.dirs(~ismember(obj.dirs,obj.stat(obj.bExistStat & obj.bDirStat)));
        bDir=repmat(obj.bDirIter',size(obj.iter,1),1);
        iterfiles=obj.iter(obj.bExistIter & ~bDir);
        obj.extra=obj.files( ~ismember(obj.files, [obj.stat(obj.bExistStat & ~obj.bDirStat); iterfiles(:)]));
    end
%% FILE CREATE
    function mkdir(obj)
        obj.exists();
        obj.mkdir_();
    end
    function touch(obj)
        obj.exists();
        obj.touch_();
    end
    function rm(obj)
        obj.isExtra();
        obj.rm_();
    end
%% LS
    function out=lsExpanded(obj)
        N=obj.Names(obj.IND & obj.bExpanded);
        V=obj.List(obj.IND & obj.bExpanded);
        T=[N V];
        T=Cell.toStr(T);

        if nargout < 1
            disp(T);
        else
            out=Str.tabify(T);
        end
    end
    function out=lsVars(obj)
        STR=[ ...
            'Vars: ' newline ...
            obj.lsStat() newline newline ...
            ...
            'Iter Fields: ' newline ...
            obj.lsIter() newline newline ...
            ...
            'Expanded: ' newline ...
            obj.lsExpanded newline ...
            ];
        if nargout < 1
            disp(STR);
        else
            out=STR;
        end
    end
    function out=lsContents(obj)
        IND=obj.IND & obj.bCnt;
        N=obj.Names(IND);
        L=obj.List(IND);
        C=obj.Cnt(ismember(find(obj.bCnt),find(obj.IND)));

        T={};
        for i = 1:length(N)
            T=[T; N(i) L(i); ' ' C{i} ];
        end
        T=Cell.toStr(T);

        if nargout < 1
            disp(T);
        else
            out=Str.tabify(T);
        end

    end
    function out=lsStat(obj)
        V=Vec.col(obj.statVar);
        i=ismember(V,obj.Names(obj.bOptional));
        V(i)=strcat('[',V(i),']');
        [V,i]=sort(V);
        E=Vec.col(obj.statVal);
        T=[V  E(i)];
        T=Cell.toStr(T);

        if nargout < 1
            disp(T);
        else
            out=Str.tabify(T);
        end
    end
    function out=lsIter(obj)
        T=[Vec.col(obj.iterVar)  Vec.col(obj.iterVal)];
        cind=cellfun(@iscell,T);
        T{cind}='true';
        T=Cell.toStr(T);
        if nargout < 1
            disp(T);
        else
            out=Str.tabify(T);
        end
    end
%% basic
    function reexpand(obj,bHard)
        % TEST
        if nargin < 2
            bHard=false;
        end
        obj.clearAll(false);
        sArgs=cell(1,length(obj.statVar)*2);
        for i = 1:length(obj.statVar)
            sArgs(i*2-1)=obj.statVar{i};
            sArgs(i*2)=obj.statVal{i};
        end
        iArgs=cell(1,length(obj.iterVar)*2);
        for i = 1:length(obj.iterVar)
            iArgs(i*2-1)=obj.iterVar{i};
            iArgs(i*2)=obj.iterVar{i};
        end
        args=[sArgs iArgs];
        obj.expand(bHard,args{:});
    end
    function expand(obj,bHard,varargin)
        flds=varargin(1:2:end);
        vars=varargin(2:2:end);

        selflds=ismember(flds,obj.selVars(:,1));
        if any(selflds)
            selvals=vars(selflds);
            obj.IND=ismember(obj.selInd,selvals);
        end

        obj.iterVal=cell(size(obj.iterVar));
        for i = 1:length(vars)
            ind=ismember(obj.iterVar,flds{i});
            obj.iterVal(ind)=vars(i);
        end
        obj.statVal=cell(size(obj.statVar));
        for i = 1:length(vars)
            ind=ismember(obj.statVar,flds{i});
            obj.statVal(ind)=vars(i);
        end

        iind=ismember(flds, obj.iterVar);
        sind=ismember(flds, obj.statVar);
        cind=ismember(flds, obj.cntReq);
        iterflds=flds(iind);
        statflds=flds(sind);
        badflds=flds(~sind & ~iind & ~selflds);

        if ~isempty(badflds)
            str=strjoin(badflds,[' ' newline]);
            error(['Invalid fields: ' newline '  ' str]);
        end

        iind=find(iind);
        sind=find(sind);
        cind=find(cind);
        iind=sort([iind*2-1, iind*2]);
        sind=sort([sind*2-1, sind*2]);
        cind=sort([cind*2-1, cind*2]);
        if ~isempty(sind)
            obj.expandStat(bHard,varargin{sind});
        end

        if ~isempty(iind)
            obj.expandIter(bHard,varargin{iind});
        end
        if ~isempty(cind)
            obj.expand_contents(varargin{cind});
        end
    end
%%% INDIVIDUAL
    function out=exist(obj,name)
        if nargin < 2 || isempty(name)
            obj.existsAll();
            return
        end
        [fname,seli]=obj.get(name);
        if obj.bDir(seli)
            out=Dir.exist(fname);
        else
            out=Fil.exist(fname);
        end
    end
    function [out,seli]=get(obj,name,varargin)
        bSoft=false;
        [out,seli]=obj.get_(name,'val',bSoft,varargin{:});
    end
    function out=delete(obj,name)
        fname=obj.get_name();
        if ~Fil.exist(fname);
            error(['Cannot delete. File already does not exist: ' fname]);
        end
        % XXX VERIFY
        delete(fname);
    end

%% VARS
    function [out,seli]=getVarStr(obj,name)
        [out,seli]=obj.get_(name,'var');
    end
    function [vars,vals]=getVar(obj,name)
        [out,seli]=obj.get_(name,'var');
        re='@([A-Za-z][A-Za-z0-9_]*)';
        vars=regexp(out,re,'tokens');
        vars=vertcat(vars{:});

        ind=cell2mat(cellfun(@(x) find(ismember(obj.statVar,x)),vars,'UniformOUtput',false));
        if ~isempty(ind)
            vals=Vec.col(obj.statVal(ind));
        end
        ind=cell2mat(cellfun(@(x) find(ismember(obj.iterVar,x)),vars,'UniformOutput',false));
        if ~isempty(ind)
            vals=Vec.col(obj.statVal(ind));
        end
    end
    function change(obj,name,val)
        % TEST
        obj.clear(name,false);
        ind=ismember(obj.statVar,name);
        if any(ind)
            obj.statVal=val;
        end
        ind=ismember(obj.iterVar,name);
        if any(ind)
            obj.iterVal=val;
        end
        obj.reexpand();
    end
    function clear(obj,name,bReexpand)
        % TEST
        if nargin < 3
            bReexpand=true;
        end
        %if nargin < 2 || isempty(name)
        %    obj.clearAll();
        %    return
        %end
        bSuccess=false;
        sind=ismember(obj.statVar,name);
        if any(sind) && ~isempty(obj.statVal{sind})
            obj.statVal{sind}=[];
            bSuccess=true;
        end

        iind=ismember(obj.iterVar,name);
        if any(iind) && ~isempty(obj.iterVal{iind})
            obj.iterVal{itterVal}=[];
            bSuccess=true;
        end
        if ~bSuccess
            error(['Value was already cleared: ' name]);
        end
        if obj.bReexpand
            obj.reexpand();
        end
    end
%% FILE CONTENTS

    function out=getCnt(obj,name)
        [out,seli]=obj.get_(name,'cnt');
    end
    function out=contentRead(obj,name)
        fname=obj.getCnt(name);
        out=Fil.cell(fname);
    end
    function out=contentMatches(obj,name)
        re='@([A-Za-z][A-Za-z0-9_]*)';
        ind=obj.bCnt &  obj.IND;
        Names=obj.Names(ind);

        contents=obj.fileRead(name);
        seli=ismember(Names,name);

        C=obj.Cnt(ismember(find(obj.bCnt),find(obj.IND)));
        C=C{seli};
        if ~obj.bExpCnt(seli)
            [m]=regexp(strjoin(C,newline),re,'match');
            m=strjoin(unique(m),[newline '  ']);
            error(['Contents not expanded; missing fields: ' newline '  ' m]);
        end
        out=ismember(C,content);

    end
    function out=contentAppend(obj,name)
        obj.contentWrite_(name,'append');
    end
    function out=contentWrite(obj,name)
        obj.contentWrite_(name,'write');
    end
    function out=contentRewrite(obj,name)
        obj.contentWrite_(name,'rewrite');
    end
    % WRITE
%% GET
end
%% PRIVATE
methods(Access=protected)
    function mkdir_(obj)
        dirs=obj.stat(~obj.bExistStat(obj.bDirStat));
        if ~isempty(dirs)
            cellfun(@Dir.mk,dirs);
        end
    end
    function touch_(obj)
        statfiles=obj.stat(~obj.bExistStat(~obj.bDirStat));
        bDir=repmat(obj.bDirIter',size(obj.iter,1),1);
        iterfiles=obj.iter(~obj.bExistIter & ~bDir);
        if ~isempt(statFiles)
            cellfun(@Fil.touch,statfiles);
        end
        if ~isempt(iterFiles)
            cellfun(@Fil.touch,iterfiles);
        end
    end
    function rm_(obj)
        % TODO verify

m       statfiles=obj.stat(~obj.bExistStat(~obj.bDirStat));
        bDir=repmat(obj.bDirIter',size(obj.iter,1),1);
        iterfiles=obj.iter(~obj.bExistIter & ~bDir);

        cellfun(@delete,statfiles);
        cellfun(@delete,iterfiles);

        if ~isempty(obj.extra)
            extrafiles=obj.extra(cellfun(@Fil.exist,obj.extra));
            extradirs=obj.extra(cellfun(@dirs.exist,obj.extra));
            if ~isempty(obj.extrafiles)
                cellfun(@delete,extrafiles);
            end
            if ~isempty(obj.extradirs)
                cellfun(@rmdir,extradirs);
            end
        end

        dirs=obj.stat(~obj.bExistStat(obj.bDirStat));
        cellfun(@rmdir,dirs);
    end
    function rename_(obj,newName)
        root=obj.stat{ismember(obj.statNames,'root')};
        base=obj.stat{ismember(obj.statNames,'base')};
        new=[Dir.parse(root) newName];
        if Dir.exist(new)
            error(['Directory already exists ' newline '  ' new]);
        end
        movefile(base,new);
    end
    function ln_(obj,lnDest)
        base=obj.stat{ismember(obj.statNames,'base')};
        if Dir.exist(new)
            error(['Directory already exists ' newline '  ' lnDest]);
        end
        FilDir.easyln(base,lnDest);
    end
    function identify(obj)
        obj.bDir=endsWith(obj.List,'/') & ~obj.bRe;
        obj.bDir(obj.bRe)=endsWith(obj.Re(obj.bRe,1),'/');
    end
    function expand_schema(obj)
        Tbl={};
        Var=cell(0,2);
        Ind={};
        Names={};
        bCnt=false(0);
        Cnt={};
        C=0;
        FileVars={};
        Re=cell(0,2);
        bRegexp=false(0);
        expand_fun(obj.fss,'',true,'',true,false);
        obj.List=Tbl;
        obj.selVars=Var;
        obj.selInd=Ind;
        obj.bRe=bRegexp;
        obj.Re=Re;
        obj.Names=Names;
        obj.bCnt=bCnt;
        obj.Cnt=Cnt;
        function  expand_fun(d,parent,bAppend,rootpar,bDict,bContents)
            if bDict
                kees=d.keys;
                vals=d.vals;
            else
                vals=d;
                kees=d;
            end
            K=cell(numel(d),1);
            N=cell(numel(d),1);
            for i = 1:numel(d)
                try
                    bD=bDict && ~isempty(d{i}{0});
                catch
                    bD=false;
                end
                if bD
                    K{i}=d{i}{0};
                    N{i}=kees{i};
                else
                    K{i}=kees{i};
                    N{i}=kees{i};
                end
            end
            INDS=1:numel(d);

            isubt=Vec.col(Str.RE.ismatch(N,'^-'));
            subt=N(isubt);
            if ~isempty(subt)
                subt=regexprep(subt,'^-','');
                rmind=ismember(N,subt);
                INDS(isubt | rmind) = [];
            end

            selind=contains(N,'.');
            if any(selind)
                sels=N(selind);
                out=cellfun(@(x) strsplit(x,'.'),sels,'UniformOutput',false);
                out=vertcat(out{:});
                [vars,~,c]=unique(out(:,1));
                for b = 1:length(vars)
                    Var{end+1,1}=vars{b};
                    Var{end,2}=out(c==b,2);
                end
                N(selind)=out(:,2);
            else
                out=[];
            end

            for i = INDS
                bDict=isa(vals{i},'dict');
                bNest=bDict || isa(vals{i},'cell');
                k=K{i};
                n=N{i};

                if bAppend
                    new=[parent k];
                elseif ~bDict
                    new='';
                end

                if ~isempty(out)
                    r=[rootpar out{i,2}];
                else
                    r=rootpar;
                end

                bC=bNest && ischar(k) && ~endsWith(k,filesep) || bContents;
                if bC & ~bContents
                    C=sum(bCnt)+1;
                    Cnt{C,1}={};
                elseif bContents
                    Cnt{C}=[Cnt{C} k];
                end

                if bNest
                    expand_fun(d{i},new,true,r,bDict,bC);
                end

                if ~bAppend || bContents
                    return
                end

                bCnt(end+1,1)=bC;
                Ind{end+1,1}=r;;
                bRe=ischar(k) && startsWith(k,'//') && endsWith(k,'//');
                Tbl{end+1,1}=new;
                bRegexp(end+1,1)=bRe;
                Names{end+1,1}=n;

                % RE
                if ~bRe
                    Re(end+1,:)={'',''};
                else
                    spl=strsplit(k,'//');
                    if spl{end}=='/'
                        Re(end+1,:)={strjoin(spl(2:3)), ''};
                    elseif spl{3}(1)== '/'
                        spl{2}=[spl{2} spl{3}(1)];
                        spl{3}=spl{3}(2:end);
                        Re(end+1,:)=spl(2:3);
                    else
                        Re(end+1,:)=spl(2:3);
                    end
                end
            end

        end
    end
    function get_cnt_req(obj)
        re='@([A-Za-z][A-Za-z0-9_]*)';
        C=obj.Cnt(ismember(find(obj.bCnt),find(obj.IND)));
        C=[C{:}];
        m=regexp(C,re,'tokens');
        m=[m{:}];
        obj.cntReq=unique([m{:}]);
    end
    function get_stat_req(obj)
        re='@([A-Za-z][A-Za-z0-9_]*)';
        m=regexp(obj.List(~obj.bRe & ~obj.bOptional),re,'tokens');
        m=[m{:}];
        obj.statReq=unique([m{:}]);

        m=regexp(obj.List(~obj.bRe),re,'tokens');
        m=[m{:}];
        obj.statVar=unique([m{:}]);
    end
    function get_iter_req(obj)
        re='@([A-Za-z][A-Za-z0-9_]*)';
        m=regexp(obj.List(obj.bRe & ~obj.bOptional),re,'tokens');
        m=[m{:}];
        obj.iterReq=unique([m{:}]);
        obj.iterReq=obj.iterReq(~ismember(obj.iterReq, obj.statReq));


        m=regexp(obj.List(obj.bRe),re,'tokens');
        m=[m{:}];
        obj.iterVar=unique([m{:}]);
        obj.iterVar=obj.iterVar(~ismember(obj.iterVar, obj.statVar));
    end
    function isExpanded(obj)
        obj.bExpanded=~contains(obj.List,'@');
        if ~isempty(obj.iter)
            obj.bExpIter=~contains(obj.iter(1,:),'@');
        end
        ind=ismember(find(obj.bCnt),find(obj.IND));
        C=obj.Cnt(ind);
        C=vertcat(C{:});
        obj.bExpCnt(ind)=all(~contains(obj.List,'@'));
    end
    function expandStat(obj,bHard,varargin)

        vars=struct(varargin{:});
        flds=fieldnames(vars);

        if bHard && any(~ismember(obj.statReq,flds))
            str=strjoin(obj.statReq(~ismember(obj.statReq,flds)),['  ' newline]);
            error(['Missing fields: ' newline '  ' str]);
        elseif any(~ismember(flds,obj.statVar))
            str=strjoin(flds(~ismember(flds,obj.statVar)),[' ' newline]);
            error(['Invalid fields: ' newline '  ' str]);
        end

        for i = 1:length(flds)
            f=flds{i};
            vars.(f)=Dir.parseRev(vars.(f));
            re=['\<@' f '\>'];
            obj.List(obj.IND)=regexprep(obj.List(obj.IND),re,vars.(f));
        end
    end
    function expand_contents(obj,varargin)
        vars=struct(varargin{:});
        flds=fieldnames(vars);

        ind=ismember(find(obj.bCnt),find(obj.IND));
        C=obj.Cnt(ind);
        for c = 1:length(C)
            for i = 1:length(flds)
                f=flds{i};
                re=['\<@' f '\>'];
                C{c}=regexprep(C{c},re,vars.(f));
            end
        end
        obj.Cnt(ind)=C;
    end
    function expandIter(obj,bHard,varargin)
        flds=varargin(1:2:end);
        vars=varargin(2:2:end);
        for i = 1:length(vars)
            if isnumeric(vars{i})
                vars{i}=num2cell(vars{i});
            elseif ~iscell(vars{i})
                vars{i}={vars{i}};
            end
        end

        if bHard && any(~ismember(obj.iterReq,flds))
            str=strjoin(obj.iterReq(~ismember(obj.iterReq,flds)),['  ' newline]);
            error(['Missing fields: ' newline '  ' str]);
        elseif any(~ismember(flds,obj.iterReq))
            str=strjoin(flds(varInds),[' ' newline]);
            error(['Invalid fields: ' newline '  ' str]);
        end

        % BUILT FRMT
        bSelRe=obj.IND & obj.bRe;

        obj.iter=obj.expandIter_fun(bSelRe,flds,vars);

        obj.bDirIter=obj.bDir(bSelRe);
        obj.bOptIter=obj.bOptional(bSelRe);
        obj.iterNames=obj.Names(bSelRe);
    end
    function iter=expandIter_fun(obj,bSelRe,flds,vars)
        types=cellfun(@class,vars,'UniformOutput',false);
        selRe=obj.Re(any(bSelRe,2),:);
        STRS=selRe(:,2)';

        frmtRe=['%[-+ 0#]*[0-9]*\.?[0-9]*[diuoxXfeEgGcs]'];
        %frmt=cell(,length(flds))
        for v=1:length(flds)
            str1=['@(' flds{v} ')\\(' frmtRe ')?'];
            str2=['@(' flds{v} ')'];
            t1=regexp(STRS,str1,'tokens');
            t2=regexp(STRS,str2,'tokens');
            for i = 1:length(t1)
                if isempty(t1{i}) && (strcmp(types{v},'cell') || strcmp(types{v},'char'))
                    STRS{i}=strrep(STRS{i},['@' t2{i}{1}{1}],['%' num2str(v) ]);
                    frmt{i,v}='%s';
                elseif ~isempty(t1{i}{1}{2})
                    frmt{i,v}=t1{i}{1}{2};
                    STRS{i}=strrep(STRS{i},['@' t2{i}{1}{1} '\' t1{i}{1}{2}],['%' num2str(v)]);
                end
            end
        end

        % BUILD NAMES
        N=prod(cellfun(@numel,vars));
        OUT=repmat(STRS,N,1);
        for s = 1:numel(STRS)
            out=cell(numel(flds),1);
            for f = 1:numel(flds)
                v=vars{f};
                if ~iscell(v)
                    v={v};
                end
                out{f}=cellfun(@(x) sprintf(frmt{s,f},x),v,'UniformOutput',false);
            end
            st=Set.distribute(out{:});
            for i = size(st,2):-1:1
                v=vars{f};
                if ~iscell(v)
                    v={v};
                end
                OUT(:,s)=cellfun(@(x,y) strrep(y,['%' num2str(i)],x),st(:,i),OUT(:,s),'UniformOutput',false);
            end
        end

        % ADD FULLPATHS TO NAMES
        Re=strcat('//', selRe(:,1), '//', selRe(:,2),'//');
        iter=cell(size(OUT));
        S=obj.List(bSelRe);

        for s= 1:numel(Re)
            iter(:,s)=cellfun(@(x) strrep(S{s},Re{s},x), OUT(:,s),'UniformOutput',false);
        end

    end
    function contentWrite_(obj,name,mode)
        re='@([A-Za-z][A-Za-z0-9_]*)';

        ind=obj.bCnt &  obj.IND;
        Names=obj.Names(ind);
        if ~ismember(name,Names)
            error(['Invalid name: ' name]);
        end
        List=obj.List(ind);
        seli=ismember(Names,name);
        fname=List{seli};
        %out=Fil.cell(fname);

        C=obj.Cnt(ismember(find(obj.bCnt),find(obj.IND)));
        C=C{seli};
        if ~obj.bExpCnt(seli)
            [m]=regexp(strjoin(C,newline),re,'match');
            m=strjoin(unique(m),[newline '  ']);
            error(['Contents not expanded; missing fields: ' newline '  ' m]);
        end
        switch mode
        case 'append'
            Fil.append(fname,C);
        case 'write'
            File.write(fname,C);
        case 'rewrite'
            File.write(fname,C,true);
        end
    end
    function [out,seli]=get_(obj,name,mode,bSoft,varargin)
        re='@([A-Za-z][A-Za-z0-9_]*)';
        if nargin < 4
            bSoft=false;
        end

        switch mode
        case 'var'
            ind=true(size(obj.IND));
            bTest=false;
        case 'val'
            if nargin > 0
                ind=true(size(obj.IND));
            else
                ind=obj.IND;
            end
            bTest=~bSoft;
        case 'cnt'
            ind=obj.IND & obj.bCnt;
            C=obj.Cnt(ismember(find(obj.bCnt),find(obj.IND)));
            bTest=~bSoft && ~obj.bExpCnt(seli);
        end
        Names=obj.Names(ind);
        if ~ismember(name,Names)
            error(['Invalid name: ' name]);
        end
        seli=ismember(Names,name);
        if strcmp(mode,'var') || numel(varargin) > 0
            Orig=obj.Orig(ind);
            out=Orig{seli};
        else
            List=obj.List(ind);
            out=List{seli};
            if strcmp(mode,'cnt')
                out=C{out};
            end
        end
        if numel(varargin) > 0
            % TODO do this sorting elsewhere, prevent partial replacemetns
            flds=varargin(1:2:end);
            vars=varargin(2:2:end);
            [flds,ind]=sort(flds);
            flds=flipud(flds);
            vars=vars(flipud(ind));
            out=obj.expandIter_fun(seli,flds,vars);
            out=unique(out);

        end
        if bTest
            if iscell(out)
                [m]=regexp(strjoin(out,newline),re,'match');
            else
                [m]=regexp(out,re,'match');
            end
            m=strjoin(unique(m),[newline '  ']);
            if ~isempty(m)
                error(['Contents not expanded; missing fields: ' newline '  ' m]);
            end
        end
    end
end
methods(Access=protected)
    %function out=getHeader(obj)
    %    out='';
    %end
    function out=getFooter(obj)
        out=[obj.lsVars];
    end
end
end

classdef Veri < handle
properties
    dbv
    fsv
    mms

    db_cfg_fname
    fs_schema_fname
    db_schema_fname

    fsList
    dbList

    bBehindDB
    bAheadOfDB
end
methods(Static)
    function test()
        pkgCfg='/home/dambam/Documents/MATLAB/.px/prj/Veri/cfg/.px';
        usrCfg='/home/dambam/Documents/MATLAB/.px/prj/Veri/cfg/Imap.config';
        obj=Veri.fromCfgs(pkgCfg,usrCfg);
    end
    function obj=fromCfgs(pkg_cfg_fname, usr_cfg_fname)
        usr=Cfg.read(usr_cfg_fname);
        pkg=Cfg.read(pkg_cfg_fname);
        Veri(pkg{'env'}{'db_schema_fname'},pkg{'env'}{'fs_schema_fname'},usr{'db_config_fname'});
    end
end
methods
    function obj=Veri(db_schema_fname,fs_schema_fname,db_config_fname)
        obj.db_schema_fname=db_schema_fname;
        obj.fs_schema_fname=fs_schema_fname;
        obj.db_config_fname=db_cfg_fname;

        obj.fsv=obj.read(fs_schema_fname,fs_vargs{:});
        obj.dbv=obj.read(db_config_fname,db_schema_fname,fs_vargs{:});
    end
%% BASE
    function out=exists(obj,name)
        out=fsv.existBase(name);
        out=dbv.existKey(name);
    end
    function out=getCompletion(obj,name)
        dbv.getCompletion(name);
        dbf.getCompletion(name);
    end
    function [notInFs,notInDB]=getMissing(obj,name)
        dbP=obj.dbv.getProgress(name);
        fsP=obj.fsv.getProgress(name);

        notInFS=dbP(~ismember(dbP,fsP));
        notInDB=fsV(~ismember(fsP,dbP));
    end
    function out=init(obj,name)
    end
    function out=backup(obj,name)
    end
    function out=archive(obj,name)
        dbv.flagUpdating(name);
        fsv.archive(name);
        dbv.flagArchiave(name);
        dbv.unflagUpdating(name);
    end
    function out=rename(obj,name,newName)
        dbv.flagUpdating(name);
        fsv.renameBase(name,newName);
        dbv.rename(name,newName);
    end
    function out=unarchive(obj,name)
        dbv.flagUpdating(name);

        db.unflagArchiave(name);
        fsv.unarchive(name); % XXX

        dbv.unflagUpdating(name);
    end
    function out=delete(obj,name)
        dbv.flagUpdating(name);

        dbv.rename(name);
        fsv.rename(name);

        dbv.unflagUpdating(name);
    end
    function out=addAlias(obj,name,alias)
        dbv.flagUpdating(name);

        dbv.addAlias(name,alias);
        fsb.lnBase(name,alias);

        dbv.unflagUpdating(name);
    end
    function out=rmAlias(obj,name,alias)
        dbv.flagUpdating(name);

        dbv.rmAlias(name,alias); % XXX
        fsv.rmLnBase(name,alias); % XXX

        dbv.unflagUpdating(name);
    end
%% FIX DISPARITIES
    function out=updateToThere(obj,name,renmoteName)
        [notInFs,notInDB]=obj.getMissing(name);

        tmpf=mktmp(ext,contents)
        Rsync(remoteName,srcDir,'/','push','filesListFile',tmpf)
    end
    function out=updateFromThere(obj,name,hostname)
        [notInFs,notInDB]=obj.getMissing(name);
        obj.dbv.getLastHostname()

        tmpf=mktmp(ext,contents)
        Rsync(remoteName,srcDir,'/','pull','filesListFile',tmpf)
    end
    function obj=rmExtra(obj)
        [notInFs,notInDB]=obj.getMissing(name);
        obj.fsv.delete(notInFs);

    end
    function obj=fixMissing(obj,name)
        [notInFs,notInDB]=obj.getMissing(name);

        obj.dbv.updateProgress(name, addRunTime, progress, completion);

    end
%% MASS
    function out=getAllCompletion(obj)

    end
    function out=getAllMissing(obj)
        out=dbv.lsAll()
        out=dbv.lsRoot()
    end
    function obj=updateCompletion(obj,name)
        [progress,addRuntime,completion]=obj.fsv.getProgress(name);
        obj.dbv.updateProgress(name,addRunTime,progress,completion);
        % FILES take precident
    end
%%
    function obj=compareTimestamps(obj,name)
        dbT=obj.dbv.getLastEdited(obj,name);
        fsT=obj.fsv.getTimestamp(obj,name);

    end
end
end

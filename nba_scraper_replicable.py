#!/usr/bin/env python3
import os
import time
import random
import requests
import pandas as pd
from datetime import datetime
from nba_api.stats.endpoints import leaguegamelog, shotchartdetail, commonplayerinfo

# ============================================================
# OUTPUT FOLDER & SEASONS TO SCRAPE
# ============================================================

OUTPUT_DIR = os.path.expanduser("~/Downloads/nba_shots_by_season")

SEASONS = ["2015-16", "2019-20", "2023-24"]

HEADERS_LIST = [
    {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
     "Referer":"https://www.nba.com","Origin":"https://www.nba.com","Accept":"application/json, text/plain, */*"},
    {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X)",
     "Referer":"https://stats.nba.com","Origin":"https://stats.nba.com","Accept":"application/json, text/plain, */*"}
]

# ============================================================
#   ROTATE HEADERS (API AVOID BLOCK)
# ============================================================

def rotate_session():
    s = requests.Session()
    s.headers.update(random.choice(HEADERS_LIST))
    shotchartdetail._session = s
    commonplayerinfo._session = s
    leaguegamelog._session = s
    return s

# ============================================================
#   
# ============================================================

def safe_api_call(func, retries=6, sleep=2.0):
    for attempt in range(retries):
        try:
            return func()
        except Exception as e:
            wait = sleep + random.random()
            print(f"API call failed (attempt {attempt+1}/{retries}): {e} -- retrying in {wait:.1f}s")
            time.sleep(wait)
            rotate_session()
    return None

# ============================================================
#   
# ============================================================

def fix_columns(df):
    rename_map = {
        "SEASON":"SEASON_1","SEASON_ID":"SEASON_2","TEAM_ID":"TEAM_ID","TEAM_NAME":"TEAM_NAME",
        "PLAYER_ID":"PLAYER_ID","PLAYER_NAME":"PLAYER_NAME","GAME_DATE":"GAME_DATE","GAME_ID":"GAME_ID",
        "HTM":"HOME_TEAM","VTM":"AWAY_TEAM","EVENT_TYPE":"EVENT_TYPE","SHOT_MADE_FLAG":"SHOT_MADE",
        "ACTION_TYPE":"ACTION_TYPE","SHOT_TYPE":"SHOT_TYPE","BASIC_ZONE":"BASIC_ZONE",
        "ZONE":"ZONE_NAME","ZONE_ABBR":"ZONE_ABB","ZONE_RANGE":"ZONE_RANGE",
        "LOC_X":"LOC_X","LOC_Y":"LOC_Y","SHOT_DISTANCE":"SHOT_DIST",
        "PERIOD":"QUARTER","MINUTES_REMAINING":"MINS_LEFT","SECONDS_REMAINING":"SECS_LEFT"
    }

    rename_map = {k:v for k,v in rename_map.items() if k in df.columns}
    df = df.rename(columns=rename_map)

    desired = [
        "SEASON_1","SEASON_2","TEAM_ID","TEAM_NAME","PLAYER_ID","PLAYER_NAME",
        "GAME_DATE","GAME_ID","HOME_TEAM","AWAY_TEAM","EVENT_TYPE","SHOT_MADE",
        "ACTION_TYPE","SHOT_TYPE","BASIC_ZONE","ZONE_NAME","ZONE_ABB","ZONE_RANGE",
        "LOC_X","LOC_Y","SHOT_DIST","QUARTER","MINS_LEFT","SECS_LEFT"
    ]

    for c in desired:
        if c not in df.columns:
            df[c] = pd.NA

    return df[desired]

# ============================================================
#   ZONE CALCULATIONS 
# ============================================================

def compute_zones(df):

    def basic_zone(dist):
        try: d=float(dist)
        except: return pd.NA
        if d<=8: return "Restricted/Paint"
        if d<=16: return "Mid-Range"
        if d<=24: return "Long Mid-Range"
        return "Three-Point"

    def zone_range(dist):
        try: d=float(dist)
        except: return pd.NA
        if d<=8: return "<8 ft"
        if d<=16: return "8-16 ft"
        if d<=24: return "16-24 ft"
        return "3PT"

    def zone_name(x,y):
        try: x=float(x); y=float(y)
        except: return pd.NA
        if abs(x)<80: return "Center"
        return "Right Side" if x>0 else "Left Side"

    def zone_abbr(name):
        if name=="Center": return "C"
        if name=="Right Side": return "RS"
        if name=="Left Side": return "LS"
        return pd.NA

    df["BASIC_ZONE"]=df["SHOT_DIST"].apply(basic_zone)
    df["ZONE_RANGE"]=df["SHOT_DIST"].apply(zone_range)
    df["ZONE_NAME"]=df.apply(lambda r: zone_name(r["LOC_X"], r["LOC_Y"]),axis=1)
    df["ZONE_ABB"]=df["ZONE_NAME"].apply(zone_abbr)

    return df

# ============================================================
#   GET ALL GAME IDS FOR A SEASON
# ============================================================

def fetch_game_ids_for_season(season):
    res = safe_api_call(lambda: leaguegamelog.LeagueGameLog(
        season=season, season_type_all_star="Regular Season"
    ))
    if res is None:
        return []
    df = res.get_data_frames()[0]
    return df["GAME_ID"].unique().tolist()

# ============================================================
#   FETCH SHOTS FOR ONE GAME (ALL SHOTS, MADE + MISSED)
# ============================================================

def fetch_shots_for_game(game_id, season):

    res = safe_api_call(lambda: shotchartdetail.ShotChartDetail(
        game_id_nullable=game_id,
        season_nullable=season,
        season_type_all_star="Regular Season",
        context_measure_simple="FGA",
        team_id=0,
        player_id=0
    ))

    if res is None:
        return pd.DataFrame()

    df = res.get_data_frames()[0]

    if "GAME_DATE" not in df.columns:
        df["GAME_DATE"] = pd.NA

    df["SEASON_1"] = season
    df["GAME_ID"] = game_id

    return df

# ============================================================
#   PLAYER BIOS (HEIGHT, WEIGHT, POSITION, BIRTHDATE)
# ============================================================

def get_player_bio_map(pids):
    bio={}
    for pid in pids:
        if pd.isna(pid): continue
        pid_int=int(pid)
        print(f"Fetching bio for player {pid_int}...")

        res=safe_api_call(lambda: commonplayerinfo.CommonPlayerInfo(player_id=pid_int))
        time.sleep(0.6+random.random())

        if res is None:
            bio[pid_int]={"PLAYER_HEIGHT":None,"PLAYER_WEIGHT":None,"PLAYER_POSITION":None,"PLAYER_BIRTHDATE":None}
            continue

        try:
            d=res.get_data_frames()[0].iloc[0].to_dict()
            bio[pid_int]={
                "PLAYER_HEIGHT":d.get("HEIGHT"),
                "PLAYER_WEIGHT":d.get("WEIGHT"),
                "PLAYER_POSITION":d.get("POSITION"),
                "PLAYER_BIRTHDATE":d.get("BIRTHDATE")
            }
        except:
            bio[pid_int]={"PLAYER_HEIGHT":None,"PLAYER_WEIGHT":None,"PLAYER_POSITION":None,"PLAYER_BIRTHDATE":None}

    return bio

def attach_player_bios(df):
    df["PLAYER_ID"]=df["PLAYER_ID"].astype("Int64",errors="ignore")
    pids=df["PLAYER_ID"].dropna().unique().tolist()

    bio=get_player_bio_map(pids)
    bio_df=pd.DataFrame.from_dict(bio,orient="index").reset_index().rename(columns={"index":"PLAYER_ID"})

    merged=df.merge(bio_df,on="PLAYER_ID",how="left")

    def compute_age(row):
        try:
            if pd.isna(row["PLAYER_BIRTHDATE"]) or pd.isna(row["GAME_DATE"]): return None
            b=pd.to_datetime(row["PLAYER_BIRTHDATE"]); g=pd.to_datetime(row["GAME_DATE"])
            return round((g-b).days/365,2)
        except:
            return None

    merged["PLAYER_AGE"]=merged.apply(compute_age,axis=1)
    return merged

# ============================================================
#   MAIN SCRAPER
# ============================================================

def main():
    os.makedirs(OUTPUT_DIR,exist_ok=True)
    rotate_session()

    for season in SEASONS:

        print(f"\n=== Processing season {season} ===")
        game_ids=fetch_game_ids_for_season(season)

        if not game_ids:
            print(f"No games for {season}, skipping.")
            continue

        frames=[]

        for i,gid in enumerate(game_ids,1):
            print(f"[{i}/{len(game_ids)}] Game {gid} ...")

            df=fetch_shots_for_game(gid,season)
            if df.shape[0]==0: continue

            if "GAME_DATE" in df.columns:
                try: df["GAME_DATE"]=pd.to_datetime(df["GAME_DATE"]).dt.date
                except: pass

            df=fix_columns(df)
            df=compute_zones(df)
            frames.append(df)

            time.sleep(0.6+random.random())

        if not frames:
            print(f"No shot rows for {season}.")
            continue

        season_df=pd.concat(frames,ignore_index=True)
        season_df=attach_player_bios(season_df)

        out=os.path.join(OUTPUT_DIR,f"{season.replace('/','-')}_SHOTS_UPDATED.csv")
        season_df.to_csv(out,index=False)

        print(f"Saved: {out}  ({len(season_df)} rows)")
        time.sleep(2+random.random())

if __name__=="__main__":
    main()

MERGE INTO pkt_prty_fncl_st ppst
USING tmp_pkt_prty_fstate_clnb_stgg tmp
   ON (tmp.fncl_ast_id = ppst.fncl_ast_id
  AND tmp.prty_id = ppst.prty_id
  AND tmp.pkt_pcsg_st_cd = ppst.pkt_pcsg_st_cd
  AND tmp.prcs_dt_clctn_st_id = ppst.prcs_dt_clctn_st_id )
 WHEN MATCHED THEN UPDATE 
  SET ppst.pkt_prty_cl_in_ipti_amt = tmp.pkt_prty_cl_in_ipti_amt,
      pkt_prty_cl_in_pubd_dfi_amt = tmp.pkt_prty_cl_in_pubd_dfi_amt,
      pkt_prty_cl_in_pubd_dt = tmp.pkt_prty_cl_in_pubd_dt,
      pkt_prty_cl_in_pubd_ipt_rt = tmp.pkt_prty_cl_in_pubd_ipt_rt,
      pkt_prty_cl_in_schd_prin_amt = tmp.pkt_prty_cl_in_schd_prin_amt,
      pkt_prty_cl_in_upb_amt = tmp.pkt_prty_cl_in_upb_amt,
      pkt_prty_cl_in_usch_prin_amt = tmp.pkt_prty_cl_in_usch_prin_amt,
      pkt_prty_pr_cl_in_pubd_upb_amt= tmp.pkt_prty_pr_cl_in_pubd_upb_amt,
      last_upd_dt =i_pcsg_dt ;

UPDATE pkt_prty_fncl_st ppst
   SET ( pkt_prty_cl_in_ipti_amt,
         pkt_prty_cl_in_pubd_dfi_amt,
         pkt_prty_cl_in_pubd_dt,
         pkt_prty_cl_in_pubd_ipt_rt,
         pkt_prty_cl_in_schd_prin_amt,
         pkt_prty_cl_in_upb_amt,
         pkt_prty_cl_in_usch_prin_amt,
         pkt_prty_pr_cl_in_pubd_upb_amt,
         last_upd_dt) =
      ( SELECT tmp.pkt_prty_cl_in_ipti_amt,
               tmp.pkt_prty_cl_in_pubd_dfi_amt,
               tmp.pkt_prty_cl_in_pubd_dt,
               tmp.pkt_prty_cl_in_pubd_ipt_rt,
               tmp.pkt_prty_cl_in_schd_prin_amt,
               tmp.pkt_prty_cl_in_upb_amt,
               tmp.pkt_prty_cl_in_usch_prin_amt,
               tmp.pkt_prty_pr_cl_in_pubd_upb_amt,
               i_pcsg_dt
          FROM tmp_pkt_prty_fstate_clnb_stgg tmp
         WHERE tmp.fncl_ast_id = ppst.fncl_ast_id
           AND tmp.prty_id = ppst.prty_id
           AND tmp.pkt_pcsg_st_cd = ppst.pkt_pcsg_st_cd
           AND tmp.prcs_dt_clctn_st_id = ppst.prcs_dt_clctn_st_id )
 WHERE EXISTS
       ( SELECT NULL
           FROM tmp_pkt_prty_fstate_clnb_stgg tmp
          WHERE tmp.fncl_ast_id = ppst.fncl_ast_id
            AND tmp.prty_id = ppst.prty_id
            AND tmp.pkt_pcsg_st_cd = ppst.pkt_pcsg_st_cd
            AND tmp.prcs_dt_clctn_st_id = ppst.prcs_dt_clctn_st_id );

"Merge vs UPDATE" 
https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:455207300346812151
						
Если есть много обновлений - я бы хотел использовать create table as select (DDL), 
чтобы я мог пропустить отмену, повтор, миграцию строк и т.д. 
Использовать merge/insert/update/delete только для небольшого количества строк 
- использование DDL только для большого количества строк.

Но если бы мне пришлось выбирать между обновлением большого количества строк с последующей вставкой 
- или слиянием (которое делает и то, и другое за один проход данных), 
- я бы использовал merge, чтобы избежать необходимости читать исходную и целевую таблицы несколько раз.
